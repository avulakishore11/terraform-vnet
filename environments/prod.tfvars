resource_group_name = "rg-winvm-prod"
location            = "eastus"
environment         = "prod"
project             = "winvm"

tags = {
  Environment = "prod"
  Project     = "winvm"
  Owner       = "Infra-team/Kishore"
  ManagedBy   = "terraform"
}

vnet_address_space      = ["10.3.0.0/16"]
subnet_address_prefixes = ["10.3.0.0/24"]

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
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.3.255.4"
  }
]

# Larger SKUs for prod
vm_size        = "Standard_D4s_v3"
admin_username = "azureadmin"

os_disk_size_gb              = 256
os_disk_storage_account_type = "Premium_LRS"

data_disk_size_gb              = 256
data_disk_storage_account_type = "Premium_LRS"
data_disk_lun                  = 0
