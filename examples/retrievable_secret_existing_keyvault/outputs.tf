output "retrievable_secret_id" {
  description = "The resource ID of the retrievable Key Vault secret."
  value       = module.retrievable_password.retrievable_secret_id
}
