$ErrorActionPreference = 'Stop'

$fixture = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\tests\fixtures\retrievable_secret_existing_keyvault'))
$prerequisites = Join-Path $PSScriptRoot 'prereqs'
$originalDataDirectory = $env:TF_DATA_DIR
if (-not (Test-Path -LiteralPath (Join-Path $fixture 'main.tf') -PathType Leaf)) {
    throw 'The prerequisite Terraform fixture is missing.'
}
$null = New-Item -ItemType Directory -Path $prerequisites -Force
Push-Location $prerequisites
try {
    $env:TF_DATA_DIR = if ($env:TF_DATA_DIR) {
        [System.IO.Path]::GetFullPath($env:TF_DATA_DIR, $prerequisites)
    } else {
        Join-Path $prerequisites '.terraform'
    }
    terraform "-chdir=$fixture" init -input=false -reconfigure "-backend-config=path=$prerequisites\terraform.tfstate" "-backend-config=workspace_dir=$prerequisites\terraform.tfstate.d"
    if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform initialization failed.' }

    terraform "-chdir=$fixture" apply -input=false -auto-approve
    if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform apply failed.' }

    $keyVaultId = terraform "-chdir=$fixture" output -raw key_vault_id
    if ($LASTEXITCODE -ne 0) { throw 'Reading the prerequisite Key Vault ID failed.' }

    $secretName = terraform "-chdir=$fixture" output -raw secret_name
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
