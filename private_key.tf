ephemeral "tls_private_key" "this" {
  count = var.private_key != null ? 1 : 0

  algorithm   = var.private_key.algorithm
  ecdsa_curve = var.private_key.ecdsa_curve
  rsa_bits    = var.private_key.rsa_bits
}

# We have to provide a dummy private key to ensure that the public key can always be generated, since the public key related outputs can refer ephemeral resource only, no conditional expression is allowed.
ephemeral "tls_private_key" "dummy" {
  algorithm = "RSA"
}

ephemeral "ephemeraltls_public_key" "this" {
  count = var.private_key != null ? 1 : 0

  private_key_pem = try(ephemeral.azurerm_key_vault_secret.retrievable_secret[0].value, ephemeral.tls_private_key.this[0].private_key_pem)
}
