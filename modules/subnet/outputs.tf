output "id" {
  description = "Resource ID of the Subnet"
  value       = azurerm_subnet.this.id
}

output "name" {
  description = "Name of the Subnet"
  value       = azurerm_subnet.this.name
}
