variable "nic_name" {
  description = "Name of the Network Interface"
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

variable "subnet_id" {
  description = "Resource ID of the Subnet the NIC will attach to"
  type        = string
}

variable "tags" {
  description = "Tags applied to the Network Interface"
  type        = map(string)
  default     = {}
}
