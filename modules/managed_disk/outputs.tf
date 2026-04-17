output "id" {
  description = "Resource ID of the Managed Disk"
  value       = azurerm_managed_disk.this.id
}

output "name" {
  description = "Name of the Managed Disk"
  value       = azurerm_managed_disk.this.name
}
