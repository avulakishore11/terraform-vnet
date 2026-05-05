locals {
  location    = "eastus"
  environment = "dev"
  project     = "winvm"
  instance    = "01"

  tags = {
    Environment = "dev"
    Project     = "terrafrom"
    Owner       = "Infra-team/Kishore"
    ManagedBy   = "terraform"
    CreatedBy   = "Kishore Avula"
    Department  = "Infrastructure"
  }

vnet_address_space      = ["10.1.0.0/16"]
subnet_address_prefixes = ["10.1.0.0/24"]

# always look confluence documentation before creating any NSG rules, we have a standard set of NSG rules that we use across all environments and projects. If you need to create custom NSG rules, please refer to the documentation and follow the guidelines for naming conventions, priority settings, and allowed protocols/ports.
nsg_rules = [
  {
    name                       = "Allow-RDP-Internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }
]

routes = [
  {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"          # This route sends all outbound traffic to the firewall(and this route is indciates to public). You can modify this to be more specific if needed.
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.255.4"         # This is an example IP address for the firewall. You should replace it with the actual IP address of your firewall appliance.
  }
]

# Smaller/cheaper SKUs for dev
vm_size        = "Standard_D2s_v3"
admin_username = "azureadmin"

os_disk_size_gb              = 128
os_disk_storage_account_type = "StandardSSD_LRS"

data_disk_size_gb              = 32
data_disk_storage_account_type = "StandardSSD_LRS"
data_disk_lun                  = 0
}