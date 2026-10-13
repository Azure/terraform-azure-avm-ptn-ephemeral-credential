[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $TestRoot
)

$ErrorActionPreference = 'Stop'
$existingTerraform = Get-Command terraform -ErrorAction SilentlyContinue
if ($existingTerraform -and $existingTerraform.CommandType -in @('Alias', 'Function')) {
    throw 'A Terraform alias or function already exists; refusing to replace it.'
}
if (Test-Path -LiteralPath $TestRoot) {
    throw 'TestRoot must be a new, dedicated directory.'
}

$example = Join-Path $PSScriptRoot '..\..\examples\retrievable_secret_existing_keyvault'
$testExample = Join-Path $TestRoot 'examples\retrievable_secret_existing_keyvault'
$prerequisites = Join-Path $testExample 'prereqs'
$fixture = Join-Path $TestRoot 'tests\fixtures\retrievable_secret_existing_keyvault'
$null = New-Item -ItemType Directory -Path $prerequisites, $fixture
Copy-Item -LiteralPath (Join-Path $example 'pre.ps1'), (Join-Path $example 'post.ps1') -Destination $testExample
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\fixtures\retrievable_secret_existing_keyvault\main.tf') -Destination $fixture
$mock = @{
    Calls = [System.Collections.Generic.List[string]]::new()
    Environments = [System.Collections.Generic.List[object]]::new()
    FailedCommand = ''
    EmptyOutput = ''
    SecretName = 'synthetic-secret"with\characters'
    Fixture = $fixture
    Prerequisites = $prerequisites
    ExpectedDataDirectory = Join-Path $prerequisites '.terraform'
}

Set-Item -Path Function:\global:terraform -Value {
    if ($args[0] -cne "-chdir=$($mock.Fixture)" -or $PWD.Path -cne $mock.Prerequisites -or $env:TF_DATA_DIR -cne $mock.ExpectedDataDirectory) {
        throw 'A hook changed the configuration, state working directory or initialization data path.'
    }
    $mock.Environments.Add(@{ Directory = $PWD.Path; DataDirectory = $env:TF_DATA_DIR; Arguments = @($args) })
    $command = $args[1..($args.Count - 1)] -join ' '
    $mock.Calls.Add($command)
    $global:LASTEXITCODE = if ($mock.FailedCommand -and $command.StartsWith($mock.FailedCommand)) { 1 } else { 0 }
    if ($LASTEXITCODE -ne 0 -or $command -eq $mock.EmptyOutput) { return }
    if ($command -eq 'output -raw key_vault_id') {
        return '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/synthetic/providers/Microsoft.KeyVault/vaults/synthetic'
    }
    if ($command -eq 'output -raw secret_name') { return $mock.SecretName }
}.GetNewClosure()

function Assert-HookFailure {
    param([string] $Hook, [string] $ExpectedMessage)
    $failed = $false
    try {
        & (Join-Path $testExample $Hook)
    } catch {
        if ($_.Exception.Message -notlike "*$ExpectedMessage*") { throw }
        $failed = $true
    }
    if (-not $failed) { throw "$Hook should have failed." }
}

$originalLocation = $PWD.Path
$originalDataDirectory = $env:TF_DATA_DIR
$env:TF_DATA_DIR = $null
$variables = Join-Path $testExample 'terraform.tfvars'
try {
    & (Join-Path $testExample 'pre.ps1')
    $lines = Get-Content -LiteralPath $variables
    if (($lines[1] -replace '^secret_name = ', '' | ConvertFrom-Json) -cne $mock.SecretName) {
        throw 'The generated secret name was not correctly escaped.'
    }
    $expectedInit = "init -input=false -reconfigure -backend-config=path=$prerequisites\terraform.tfstate -backend-config=workspace_dir=$prerequisites\terraform.tfstate.d"
    if (($mock.Calls -join ';') -cne "$expectedInit;apply -input=false -auto-approve;output -raw key_vault_id;output -raw secret_name") {
        throw 'The prerequisite command sequence changed.'
    }
    foreach ($call in $mock.Environments) {
        if ($call.Directory -cne $prerequisites -or $call.DataDirectory -cne (Join-Path $prerequisites '.terraform') -or $call.Arguments[0] -cne "-chdir=$fixture") {
            throw 'The fixture source, state directory or initialization data location changed.'
        }
    }
    if ($env:TF_DATA_DIR) { throw 'The hooks did not restore TF_DATA_DIR.' }
    Remove-Item -LiteralPath $variables

    foreach ($failure in @(
        @{ Command = 'init -input=false'; Message = 'initialization failed' },
        @{ Command = 'apply -input=false -auto-approve'; Message = 'apply failed' },
        @{ Command = 'output -raw key_vault_id'; Message = 'Key Vault ID failed' },
        @{ Command = 'output -raw secret_name'; Message = 'secret name failed' }
    )) {
        $mock.FailedCommand = $failure.Command
        Assert-HookFailure -Hook 'pre.ps1' -ExpectedMessage $failure.Message
        if (Test-Path -LiteralPath $variables) { throw 'A failed setup wrote terraform.tfvars.' }
        if ($PWD.Path -cne $originalLocation) { throw 'Setup did not restore the working directory.' }
    }
    $mock.FailedCommand = ''
    $mock.EmptyOutput = 'output -raw key_vault_id'
    Assert-HookFailure -Hook 'pre.ps1' -ExpectedMessage 'must not be empty'
    if (Test-Path -LiteralPath $variables) { throw 'An empty output wrote terraform.tfvars.' }
    $mock.EmptyOutput = ''

    & (Join-Path $testExample 'pre.ps1')
    $mock.FailedCommand = 'init -input=false'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'initialization failed'
    if (-not (Test-Path -LiteralPath $variables)) { throw 'Failed cleanup initialization removed terraform.tfvars.' }
    $mock.FailedCommand = 'destroy -input=false -auto-approve'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'destroy failed'
    if (-not (Test-Path -LiteralPath $variables)) { throw 'Failed cleanup removed terraform.tfvars.' }
    if ($PWD.Path -cne $originalLocation) { throw 'Cleanup did not restore the working directory.' }

    $mock.FailedCommand = ''
    & (Join-Path $testExample 'post.ps1')
    if (Test-Path -LiteralPath $variables) { throw 'Successful cleanup retained terraform.tfvars.' }
    if ($PWD.Path -cne $originalLocation) { throw 'The hooks changed the working directory.' }
    $env:TF_DATA_DIR = '..\custom-data'
    $mock.ExpectedDataDirectory = [System.IO.Path]::GetFullPath('..\custom-data', $prerequisites)
    & (Join-Path $testExample 'pre.ps1')
    if ($mock.Environments[-1].DataDirectory -cne [System.IO.Path]::GetFullPath('..\custom-data', $prerequisites) -or $env:TF_DATA_DIR -cne '..\custom-data') {
        throw 'The caller-provided initialization data directory was not preserved.'
    }
    & (Join-Path $testExample 'post.ps1')

    Rename-Item -LiteralPath (Join-Path $fixture 'main.tf') -NewName 'main.tf.missing'
    Assert-HookFailure -Hook 'pre.ps1' -ExpectedMessage 'fixture is missing'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'fixture is missing'
    Write-Output 'Passed 12 synthetic hook cases. No Terraform binary or provider was executed.'
} finally {
    $env:TF_DATA_DIR = $originalDataDirectory
    Remove-Item -LiteralPath 'Function:\terraform'
}
