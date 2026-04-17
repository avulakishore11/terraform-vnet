output "id" {
  description = "Resource ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.this.name
}
