variable "subnet_name" {
  description = "Name of the Subnet"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the parent Virtual Network"
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes for the Subnet (CIDR)"
  type        = list(string)
}
