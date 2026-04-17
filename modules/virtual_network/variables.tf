variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network (CIDR)"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to the Virtual Network"
  type        = map(string)
  default     = {}
}
