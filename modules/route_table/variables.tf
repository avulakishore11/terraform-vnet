variable "route_table_name" {
  description = "Name of the Route Table"
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
  description = "Resource ID of the Subnet to associate the Route Table with"
  type        = string
}

variable "routes" {
  description = "List of user-defined routes"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the Route Table"
  type        = map(string)
  default     = {}
}
