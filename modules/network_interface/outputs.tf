output "id" {
  description = "Resource ID of the Network Interface"
  value       = azurerm_network_interface.this.id
}

output "private_ip_address" {
  description = "Private IP address assigned to the NIC"
  value       = azurerm_network_interface.this.private_ip_address
}
