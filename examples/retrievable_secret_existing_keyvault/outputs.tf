# Force the ephemeral output to be evaluated so a regression in the deferral
# logic (i.e. trying to read the secret during `terraform plan`) would surface
# during `terraform plan`/`terraform apply` of this example.
output "password_result_length" {
  description = "Length of the retrieved ephemeral password. Used to ensure the ephemeral read is exercised."
  ephemeral   = true
  value       = length(module.retrievable_password.password_result)
}

output "retrievable_secret_id" {
  description = "The resource ID of the retrievable Key Vault secret."
  value       = module.retrievable_password.retrievable_secret_id
}
