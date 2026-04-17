module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "virtual_network" {
  source              = "./modules/virtual_network"
  vnet_name           = "${var.project}-vnet-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

module "subnet" {
  source               = "./modules/subnet"
  subnet_name          = "${var.project}-subnet-${var.environment}"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.virtual_network.name
  address_prefixes     = var.subnet_address_prefixes
}

module "network_security_group" {
  source              = "./modules/network_security_groupcccccbtjgtclgnkhrfuilfufud"
  nsg_name            = "${var.project}-nsg-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.subnet.id
  nsg_rules           = var.nsg_rules
  tags                = var.tags
}

module "route_table" {
  source              = "./modules/route_table"
  route_table_name    = "${var.project}-rt-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.subnet.id
  routes              = var.routes
  tags                = var.tags
}

module "network_interface" {
  source              = "./modules/network_interface"
  nic_name            = "${var.project}-nic-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.subnet.id
  tags                = var.tags
}

module "virtual_machine" {
  source              = "./modules/virtual_machine"
  vm_name             = "${var.project}-vm-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  nic_id              = module.network_interface.id

  os_disk_caching              = var.os_disk_caching
  os_disk_storage_account_type = var.os_disk_storage_account_type
  os_disk_size_gb              = var.os_disk_size_gb

  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  image_version   = var.image_version

  tags = var.tags
}

module "managed_disk" {
  source              = "./modules/managed_disk"
  disk_name           = "${var.project}-datadisk-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  storage_account_type = var.data_disk_storage_account_type
  disk_size_gb        = var.data_disk_size_gb
  vm_id               = module.virtual_machine.id
  lun                 = var.data_disk_lun
  tags                = var.tags
}
