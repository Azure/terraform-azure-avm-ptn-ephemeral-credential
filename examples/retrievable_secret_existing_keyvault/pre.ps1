$ErrorActionPreference = 'Stop'

$fixture = [System.IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', 'tests', 'fixtures', 'retrievable_secret_existing_keyvault'))
$prerequisites = Join-Path $PSScriptRoot 'prereqs'
$configuration = Join-Path $prerequisites 'configuration'
$statePath = Join-Path $prerequisites 'terraform.tfstate'
$workspacePath = Join-Path $prerequisites 'terraform.tfstate.d'
$fixtureFiles = @(
    (Join-Path $fixture 'main.tf.tftpl')
    (Join-Path $fixture 'variables.tf.tftpl')
)
$originalDataDirectory = $env:TF_DATA_DIR
if ($fixtureFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }) {
    throw 'The prerequisite Terraform fixture is missing.'
}
$terraform = (Get-AvmTool -Name terraform -Path (Join-Path $PSScriptRoot '..' -AdditionalChildPath '..')).Path
if ([string]::IsNullOrWhiteSpace($terraform)) {
    throw 'Managed Terraform is unavailable. Run avm tool install terraform before running this hook.'
}
$null = New-Item -ItemType Directory -Path $prerequisites, $configuration -Force
if (-not (Test-Path -LiteralPath (Join-Path $configuration 'main.tf') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $configuration 'variables.tf') -PathType Leaf)) {
    Copy-Item -LiteralPath (Join-Path $fixture 'main.tf.tftpl') -Destination (Join-Path $configuration 'main.tf') -Force
    Copy-Item -LiteralPath (Join-Path $fixture 'variables.tf.tftpl') -Destination (Join-Path $configuration 'variables.tf') -Force
}
Push-Location $prerequisites
try {
    $env:TF_DATA_DIR = if ($env:TF_DATA_DIR) {
        [System.IO.Path]::GetFullPath($env:TF_DATA_DIR, $prerequisites)
    } else {
        Join-Path $prerequisites '.terraform'
    }
    & $terraform "-chdir=$configuration" init -input=false -reconfigure "-backend-config=path=$statePath" "-backend-config=workspace_dir=$workspacePath"
    if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform initialization failed.' }

    & $terraform "-chdir=$configuration" apply -input=false -auto-approve
    if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform apply failed.' }

    $keyVaultId = & $terraform "-chdir=$configuration" output -raw key_vault_id
    if ($LASTEXITCODE -ne 0) { throw 'Reading the prerequisite Key Vault ID failed.' }

    $secretName = & $terraform "-chdir=$configuration" output -raw secret_name
    if ($LASTEXITCODE -ne 0) { throw 'Reading the prerequisite secret name failed.' }

    if ([string]::IsNullOrWhiteSpace($keyVaultId) -or [string]::IsNullOrWhiteSpace($secretName)) {
        throw 'The prerequisite Key Vault ID and secret name must not be empty.'
    }

    $variables = @(
        "key_vault_id = $(ConvertTo-Json -InputObject ([string]$keyVaultId) -Compress)"
        "secret_name = $(ConvertTo-Json -InputObject ([string]$secretName) -Compress)"
    )
    $variables | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'terraform.tfvars') -Encoding utf8NoBOM
} finally {
    $env:TF_DATA_DIR = $originalDataDirectory
    Pop-Location
}
