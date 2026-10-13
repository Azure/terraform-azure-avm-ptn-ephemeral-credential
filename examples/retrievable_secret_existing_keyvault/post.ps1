$ErrorActionPreference = 'Stop'

$fixture = [System.IO.Path]::GetFullPath((Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', 'tests', 'fixtures', 'retrievable_secret_existing_keyvault'))
$prerequisites = Join-Path $PSScriptRoot 'prereqs'
$statePath = Join-Path $prerequisites 'terraform.tfstate'
$workspacePath = Join-Path $prerequisites 'terraform.tfstate.d'
$originalDataDirectory = $env:TF_DATA_DIR
if (-not (Test-Path -LiteralPath (Join-Path $fixture 'main.tf') -PathType Leaf)) {
    throw 'The prerequisite Terraform fixture is missing.'
}
if (Test-Path -LiteralPath $prerequisites -PathType Container) {
    Push-Location $prerequisites
    try {
        $env:TF_DATA_DIR = if ($env:TF_DATA_DIR) {
            [System.IO.Path]::GetFullPath($env:TF_DATA_DIR, $prerequisites)
        } else {
            Join-Path $prerequisites '.terraform'
        }
        terraform "-chdir=$fixture" init -input=false -reconfigure "-backend-config=path=$statePath" "-backend-config=workspace_dir=$workspacePath"
        if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform initialization failed.' }

        terraform "-chdir=$fixture" destroy -input=false -auto-approve
        if ($LASTEXITCODE -ne 0) { throw 'Prerequisite Terraform destroy failed.' }
    } finally {
        $env:TF_DATA_DIR = $originalDataDirectory
        Pop-Location
    }
}

$variables = Join-Path $PSScriptRoot 'terraform.tfvars'
if (Test-Path -LiteralPath $variables -PathType Leaf) {
    Remove-Item -LiteralPath $variables
}
