# ── Common ────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Deployment environment (dev | test | prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "project" {
  description = "Short project identifier used in resource naming"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "Address space for the Virtual Network (CIDR)"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the workload Subnet (CIDR)"
  type        = list(string)
  default     = ["10.1.0.0/24"]
}

variable "nsg_rules" {
  description = "NSG inbound/outbound security rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
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
}

variable "routes" {
  description = "User-defined routes for the Route Table"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "vm_size" {
  description = "Azure VM SKU size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Local administrator username"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local administrator password (stored in Key Vault in production)"
  type        = string
  sensitive   = true
}

variable "os_disk_caching" {
  description = "OS disk caching (None | ReadOnly | ReadWrite)"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage type (Standard_LRS | Premium_LRS | StandardSSD_LRS)"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "image_publisher" {
  description = "VM image publisher"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "VM image offer"
  type        = string
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "VM image SKU"
  type        = string
  default     = "2022-Datacenter"
}

variable "image_version" {
  description = "VM image version"
  type        = string
  default     = "latest"
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB"
  type        = number
  default     = 128
}

variable "data_disk_storage_account_type" {
  description = "Data disk storage type"
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_lun" {
  description = "Logical Unit Number for the data disk"
  type        = number
  default     = 0
}
