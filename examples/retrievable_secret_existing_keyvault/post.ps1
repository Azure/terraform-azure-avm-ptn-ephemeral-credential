$ErrorActionPreference = 'Stop'

$fixture = [System.IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', 'tests', 'fixtures', 'retrievable_secret_existing_keyvault'))
$prerequisites = Join-Path $PSScriptRoot 'prereqs'
$configuration = Join-Path $prerequisites 'configuration'
$providerCache = Join-Path $prerequisites '.terraform' -AdditionalChildPath 'provider-cache'
$statePath = Join-Path $prerequisites 'terraform.tfstate'
$workspacePath = Join-Path $prerequisites 'terraform.tfstate.d'
$fixtureFiles = @(
    (Join-Path $fixture 'main.tf.tftpl')
    (Join-Path $fixture 'variables.tf.tftpl')
)
$originalDataDirectory = $env:TF_DATA_DIR
$originalPluginCacheDirectory = $env:TF_PLUGIN_CACHE_DIR
if ($fixtureFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }) {
    throw 'The prerequisite Terraform fixture is missing.'
}
if (Test-Path -LiteralPath $prerequisites -PathType Container) {
    $terraform = (Get-AvmTool -Name terraform -Path (Join-Path $PSScriptRoot '..' -AdditionalChildPath '..')).Path
    if ([string]::IsNullOrWhiteSpace($terraform)) {
        throw 'Managed Terraform is unavailable. Run avm tool install terraform before running this hook.'
    }
    $null = New-Item -ItemType Directory -Path $configuration, $providerCache -Force
    if (-not (Test-Path -LiteralPath (Join-Path $configuration 'main.tf') -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $configuration 'variables.tf') -PathType Leaf)) {
        Copy-Item -LiteralPath (Join-Path $fixture 'main.tf.tftpl') -Destination (Join-Path $configuration 'main.tf') -Force
        Copy-Item -LiteralPath (Join-Path $fixture 'variables.tf.tftpl') -Destination (Join-Path $configuration 'variables.tf') -Force
    }
    Push-Location $prerequisites
    try {
        $env:TF_PLUGIN_CACHE_DIR = $providerCache
        $env:TF_DATA_DIR = if ($env:TF_DATA_DIR) {
            [System.IO.Path]::GetFullPath($env:TF_DATA_DIR, $prerequisites)
        } else {
            Join-Path $prerequisites '.terraform'
        }
        & $terraform "-chdir=$configuration" init -input=false -reconfigure "-backend-config=path=$statePath" "-backend-config=workspace_dir=$workspacePath"
        if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform initialization failed.' }

        & $terraform "-chdir=$configuration" destroy -input=false -auto-approve
        if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform destroy failed.' }
    } finally {
        $env:TF_DATA_DIR = $originalDataDirectory
        $env:TF_PLUGIN_CACHE_DIR = $originalPluginCacheDirectory
        Pop-Location
    }
    if (Test-Path -LiteralPath $configuration -PathType Container) {
        Remove-Item -LiteralPath $configuration -Recurse -Force
    }
}

$variables = Join-Path $PSScriptRoot 'terraform.tfvars'
if (Test-Path -LiteralPath $variables -PathType Leaf) {
    Remove-Item -LiteralPath $variables
}
