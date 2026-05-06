output "id" {
  description = "Resource ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Object ID of the identity (used for role assignments)"
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID of the identity"
  value       = azurerm_user_assigned_identity.this.client_id
}
