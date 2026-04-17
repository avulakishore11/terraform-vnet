output "id" {
  description = "Resource ID of the Route Table"
  value       = azurerm_route_table.this.id
}

output "name" {
  description = "Name of the Route Table"
  value       = azurerm_route_table.this.name
}
