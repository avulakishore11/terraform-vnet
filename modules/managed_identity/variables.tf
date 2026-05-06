variable "name" {
  description = "Name of the User Assigned Managed Identity"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy the identity into"
  type        = string
}

variable "tags" {
  description = "Tags applied to the identity"
  type        = map(string)
  default     = {}
}
