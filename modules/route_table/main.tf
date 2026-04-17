resource "azurerm_route_table" "this" {
  name                          = var.route_table_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = false

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.this.id
}
