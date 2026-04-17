variable "name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags applied to the Resource Group"
  type        = map(string)
  default     = {}
}
