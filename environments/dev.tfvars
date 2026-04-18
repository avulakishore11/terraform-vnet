resource_group_name = "rg-winvm-dev"
location            = "eastus"
environment         = "dev"
project             = "winvm"

tags = {
  Environment = "dev"
  Project     = "winvm"
  Owner       = "Infra-team/Kishore"
  ManagedBy   = "terraform"
}

vnet_address_space      = ["10.1.0.0/16"]
subnet_address_prefixes = ["10.1.0.0/24"]

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
    next_hop_in_ip_address = "10.1.255.4"
  }
]

# Smaller/cheaper SKUs for dev
vm_size        = "Standard_B2s"
admin_username = "azureadmin"

os_disk_size_gb              = 64
os_disk_storage_account_type = "StandardSSD_LRS"

data_disk_size_gb              = 64
data_disk_storage_account_type = "StandardSSD_LRS"
data_disk_lun                  = 0
