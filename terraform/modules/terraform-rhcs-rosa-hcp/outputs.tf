output "oidc_config_id" {
  value = var.create_oidc ? module.oidc_config_and_provider[0].oidc_config_id : null
}
