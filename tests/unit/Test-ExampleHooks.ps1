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
$configuration = Join-Path $prerequisites 'configuration'
$fixture = Join-Path $TestRoot 'tests\fixtures\retrievable_secret_existing_keyvault'
$null = New-Item -ItemType Directory -Path $prerequisites, $fixture
Copy-Item -LiteralPath (Join-Path $example 'pre.ps1'), (Join-Path $example 'post.ps1') -Destination $testExample
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\fixtures\retrievable_secret_existing_keyvault\main.tf.tftpl'),
    (Join-Path $PSScriptRoot '..\fixtures\retrievable_secret_existing_keyvault\variables.tf.tftpl') -Destination $fixture
$mock = @{
    Calls = [System.Collections.Generic.List[string]]::new()
    Environments = [System.Collections.Generic.List[object]]::new()
    FailedCommand = ''
    EmptyOutput = ''
    SecretName = 'synthetic-secret"with\characters'
    Fixture = $configuration
    Prerequisites = $prerequisites
    ExpectedDataDirectory = Join-Path $prerequisites '.terraform'
}

$global:__avmExampleHooksMock = $mock
Set-Item -Path Function:\global:terraform -Value {
    if ($args[0] -cne "-chdir=$($global:__avmExampleHooksMock.Fixture)" -or $PWD.Path -cne $global:__avmExampleHooksMock.Prerequisites -or $env:TF_DATA_DIR -cne $global:__avmExampleHooksMock.ExpectedDataDirectory) {
        throw 'A hook changed the configuration, state working directory or initialization data path.'
    }
    $global:__avmExampleHooksMock.Environments.Add(@{ Directory = $PWD.Path; DataDirectory = $env:TF_DATA_DIR; Arguments = @($args) })
    $command = $args[1..($args.Count - 1)] -join ' '
    $global:__avmExampleHooksMock.Calls.Add($command)
    $global:LASTEXITCODE = if ($global:__avmExampleHooksMock.FailedCommand -and $command.StartsWith($global:__avmExampleHooksMock.FailedCommand)) { 1 } else { 0 }
    if ($LASTEXITCODE -ne 0 -or $command -eq $global:__avmExampleHooksMock.EmptyOutput) { return }
    if ($command -eq 'output -raw key_vault_id') {
        return '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/synthetic/providers/Microsoft.KeyVault/vaults/synthetic'
    }
    if ($command -eq 'output -raw secret_name') { return $global:__avmExampleHooksMock.SecretName }
}

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
    foreach ($file in @('main.tf', 'variables.tf')) {
        $generatedFile = Join-Path $configuration $file
        $templateFile = Join-Path $fixture "$file.tftpl"
        if ((Get-Content -LiteralPath $generatedFile -Raw) -cne (Get-Content -LiteralPath $templateFile -Raw)) {
            throw 'The runtime Terraform configuration does not match its fixture template.'
        }
    }
    $lines = Get-Content -LiteralPath $variables
    if (($lines[1] -replace '^secret_name = ', '' | ConvertFrom-Json) -cne $mock.SecretName) {
        throw 'The generated secret name was not correctly escaped.'
    }
    $statePath = Join-Path $prerequisites 'terraform.tfstate'
    $workspacePath = Join-Path $prerequisites 'terraform.tfstate.d'
    $expectedInit = "init -input=false -reconfigure -backend-config=path=$statePath -backend-config=workspace_dir=$workspacePath"
    if (($mock.Calls -join ';') -cne "$expectedInit;apply -input=false -auto-approve;output -raw key_vault_id;output -raw secret_name") {
        throw 'The prerequisite command sequence changed.'
    }
    foreach ($call in $mock.Environments) {
        if ($call.Directory -cne $prerequisites -or $call.DataDirectory -cne (Join-Path $prerequisites '.terraform') -or $call.Arguments[0] -cne "-chdir=$configuration") {
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
    $syntheticState = 'synthetic state marker, not Terraform state'
    Set-Content -LiteralPath $statePath -Value $syntheticState -NoNewline
    $savedVariables = Get-Content -LiteralPath $variables -Raw
    $mock.FailedCommand = 'init -input=false'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'initialization failed'
    if (-not (Test-Path -LiteralPath $variables)) { throw 'Failed cleanup initialization removed terraform.tfvars.' }
    if ((Get-Content -LiteralPath $statePath -Raw) -cne $syntheticState -or (Get-Content -LiteralPath $variables -Raw) -cne $savedVariables) {
        throw 'Failed cleanup initialization changed the synthetic state or outputs.'
    }
    if (-not (Test-Path -LiteralPath $configuration -PathType Container)) { throw 'Failed cleanup initialization removed its Terraform configuration.' }
    $mock.FailedCommand = 'destroy -input=false -auto-approve'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'destroy failed'
    if (-not (Test-Path -LiteralPath $variables)) { throw 'Failed cleanup removed terraform.tfvars.' }
    if ((Get-Content -LiteralPath $statePath -Raw) -cne $syntheticState -or (Get-Content -LiteralPath $variables -Raw) -cne $savedVariables) {
        throw 'Failed cleanup changed the synthetic state or outputs.'
    }
    if (-not (Test-Path -LiteralPath $configuration -PathType Container)) { throw 'Failed cleanup removed its Terraform configuration.' }
    if ($PWD.Path -cne $originalLocation) { throw 'Cleanup did not restore the working directory.' }

    $mock.FailedCommand = ''
    & (Join-Path $testExample 'post.ps1')
    if (Test-Path -LiteralPath $variables) { throw 'Successful cleanup retained terraform.tfvars.' }
    if (Test-Path -LiteralPath $configuration) { throw 'Successful cleanup retained the generated Terraform configuration.' }
    if ($PWD.Path -cne $originalLocation) { throw 'The hooks changed the working directory.' }
    $customData = Join-Path '..' 'custom-data'
    $env:TF_DATA_DIR = $customData
    $mock.ExpectedDataDirectory = [System.IO.Path]::GetFullPath($customData, $prerequisites)
    & (Join-Path $testExample 'pre.ps1')
    if ($mock.Environments[-1].DataDirectory -cne [System.IO.Path]::GetFullPath($customData, $prerequisites) -or $env:TF_DATA_DIR -cne $customData) {
        throw 'The caller-provided initialization data directory was not preserved.'
    }
    & (Join-Path $testExample 'post.ps1')
    $customData = Join-Path $TestRoot 'absolute-data'
    $env:TF_DATA_DIR = $customData
    $mock.ExpectedDataDirectory = $customData
    & (Join-Path $testExample 'pre.ps1')
    if ($env:TF_DATA_DIR -cne $customData) { throw 'Setup changed an absolute caller-provided data directory.' }
    $mock.FailedCommand = 'destroy -input=false -auto-approve'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'destroy failed'
    if ($env:TF_DATA_DIR -cne $customData -or $PWD.Path -cne $originalLocation) {
        throw 'Failed cleanup did not restore the absolute data directory and working directory.'
    }
    $mock.FailedCommand = ''
    & (Join-Path $testExample 'post.ps1')

    foreach ($separator in @('\', '/')) {
        & {
            param($Separator, $HookDirectory)
            $examplePath = if ($Separator -eq '\') { 'Q:\synthetic scope\examples\retrievable_secret_existing_keyvault' } else { '/synthetic scope/examples/retrievable_secret_existing_keyvault' }
            function Join-Path {
                param([string] $Path, [string] $ChildPath, [string[]] $AdditionalChildPath)
                $segments = [System.Collections.Generic.List[string]]::new()
                foreach ($segment in (@($Path, $ChildPath) + $AdditionalChildPath) -split '[\\/]') {
                    if ($segment -eq '..') { $segments.RemoveAt($segments.Count - 1) }
                    elseif ($segment -ne '.' -and $segment -ne '') { $segments.Add($segment) }
                }
                $prefix = if ($Path.StartsWith('/')) { '/' } else { '' }
                return $prefix + ($segments -join $Separator)
            }
            foreach ($hook in @('pre.ps1', 'post.ps1')) {
                $tokens = $null
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    [System.IO.Path]::Combine($HookDirectory, $hook), [ref]$tokens, [ref]$errors)
                if ($errors.Count) { throw "Cannot parse $hook." }
                $assignments = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $node.Left.Extent.Text -in @('$fixture', '$prerequisites', '$configuration', '$statePath', '$workspacePath')
                }, $true))
                        if ($assignments.Count -ne 5) { throw 'Unexpected hook path assignments.' }
                foreach ($assignment in $assignments) {
                    $join = @($assignment.Right.FindAll({
                        param($node)
                        $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Join-Path'
                    }, $true))
                    if ($join.Count -ne 1 -or $join[0].Extent.Text -match '[\\/]') { throw 'Hook path joins must use individual portable segments.' }
                    $joinText = $join[0].Extent.Text.Replace('$PSScriptRoot', '$examplePath')
                    Set-Variable -Name $assignment.Left.VariablePath.UserPath -Value (& ([scriptblock]::Create($joinText)))
                }
                $expectedFixture = if ($Separator -eq '\') { 'Q:\synthetic scope\tests\fixtures\retrievable_secret_existing_keyvault' } else { '/synthetic scope/tests/fixtures/retrievable_secret_existing_keyvault' }
                $expectedConfiguration = "$examplePath${Separator}prereqs${Separator}configuration"
                if ($fixture -cne $expectedFixture -or $prerequisites -cne "$examplePath${Separator}prereqs" -or $configuration -cne $expectedConfiguration -or
                    $statePath -cne "$examplePath${Separator}prereqs${Separator}terraform.tfstate" -or
                    $workspacePath -cne "$examplePath${Separator}prereqs${Separator}terraform.tfstate.d") {
                    throw "Unexpected synthetic $Separator source or backend paths."
                }
                $dataJoins = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Join-Path' -and $node.Extent.Text -match "'\.terraform'"
                }, $true))
                if ($dataJoins.Count -ne 1 -or (& ([scriptblock]::Create($dataJoins[0].Extent.Text))) -cne "$prerequisites${Separator}.terraform") {
                    throw 'Unexpected initialization path.'
                }
                $calls = [System.Collections.Generic.List[object]]::new()
                function terraform { $calls.Add(@($args)) }
                $commands = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'terraform'
                }, $true))
                foreach ($command in $commands) { & ([scriptblock]::Create($command.Extent.Text)) }
                $expectedCommands = if ($hook -eq 'pre.ps1') {
                    @(
                        @("-chdir=$expectedConfiguration", 'init', '-input=false', '-reconfigure', "-backend-config=path=$statePath", "-backend-config=workspace_dir=$workspacePath"),
                        @("-chdir=$expectedConfiguration", 'apply', '-input=false', '-auto-approve'),
                        @("-chdir=$expectedConfiguration", 'output', '-raw', 'key_vault_id'),
                        @("-chdir=$expectedConfiguration", 'output', '-raw', 'secret_name')
                    )
                } else {
                    @(
                        @("-chdir=$expectedConfiguration", 'init', '-input=false', '-reconfigure', "-backend-config=path=$statePath", "-backend-config=workspace_dir=$workspacePath"),
                        @("-chdir=$expectedConfiguration", 'destroy', '-input=false', '-auto-approve')
                    )
                }
                if ($calls.Count -ne $expectedCommands.Count) { throw 'Unexpected hook command count.' }
                for ($i = 0; $i -lt $calls.Count; $i++) {
                    if (($calls[$i] -join "`0") -cne ($expectedCommands[$i] -join "`0")) { throw 'Hook argv changed or split a path containing spaces.' }
                }
            }
        } $separator $testExample
    }
    $fixtureText = Get-Content -LiteralPath (Join-Path $fixture 'main.tf.tftpl') -Raw
    if ($fixtureText -notmatch '(?s)module "regions" \{[^}]*enable_telemetry\s*=\s*false') {
        throw 'The fixture regions module must explicitly disable telemetry.'
    }
    Rename-Item -LiteralPath (Join-Path $fixture 'main.tf.tftpl') -NewName 'main.tf.missing'
    Assert-HookFailure -Hook 'pre.ps1' -ExpectedMessage 'fixture is missing'
    Assert-HookFailure -Hook 'post.ps1' -ExpectedMessage 'fixture is missing'
    Write-Output 'Passed 12 synthetic hook cases plus Windows/Unix source, backend, init-path and exact argv models, fixture opt-out and failed-cleanup state/output retention. No Terraform binary or provider was executed.'
} finally {
    $env:TF_DATA_DIR = $originalDataDirectory
    Remove-Item -LiteralPath 'Function:\terraform'
    Remove-Variable -Name __avmExampleHooksMock -Scope Global -ErrorAction SilentlyContinue
}
