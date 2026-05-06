# ── Common ────────────────────────────────────────────────────────────────────

variable "instance" {
  description = "Two-digit instance number appended to every resource name (e.g. 01, 02)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for all resources (e.g. eastus, westus2). Overridden per environment in dev.tfvars."
  type        = string
  default     = ""
}

# the var.environment is not referring to the varibale being defined
# it refers to the variable alreadydefined in the dev.tfvars file, which will be passed in when you run terraform plan/apply with the -var-file option. This allows you to have different values for environment (dev, test, prod) without changing the code, and it will be used in the naming convention for resources and in tags.

variable "environment" {
  description = "Deployment environment (dev | test | prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment) # var.environment  = a runtime input variable, not a compile-time variable definition
    error_message = "environment must be one of: dev, test, prod."
  }
} 

# So inside validation:

#you are NOT referencing the variable block itself
#you are referencing the incoming value of that variable

variable "project" {
  description = "Short project identifier used in resource naming"
  type        = string
}

## Tags variable to allow users to pass in custom tags for the VM. This is a map of string key-value pairs which already defined in the dev.tfvars file, and it will be applied to the VM resource when it's created. You can use this to add metadata such as environment, project, owner, etc., which can help with organization and cost management in Azure.
# Tags are a map(string) — key-value pairs applied to the VM resource.
# Passed in from the root module so all resources share the same tags.
variable "tags" {
  description = "Tags applied to every resource. Must include: CreatedBy, Owner, Department, Environment."
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for key in ["CreatedBy", "Owner", "Department", "Environment"]
      :contains(keys(var.tags), key)
               #keys map to tags only name/key not the value keys(var.tags)
              #  contains(keys(var.tags), key)contains(["Environment", "Owner"], "Environment")  → true  ✅
    ])              # var.tags is the incoming map of tags(modules/variables.tf), keys(var.tags) gives you the list of keys in that map, and contains(keys(var.tags), key) checks if each required key is present in the tags map. The alltrue function ensures that all required keys are included.
    error_message = "tags map must contain all required keys: CreatedBy, Owner, Department, Environment."
  }
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "Address space for the Virtual Network (CIDR). type = list(string) because a VNet can have multiple address spaces."
  type        = list(string) 
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the workload Subnet (CIDR). type = list(string) because a Subnet can have multiple prefixes."
  type        = list(string)
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
  # Default allows RDP only from the internal RFC-1918 10.0.0.0/8 range.
  # Override in dev.tfvars with the full nsg_rules list for your environment.
  default = []
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
  description = "Azure VM SKU size (e.g. Standard_D2s_v3). Overridden per environment in dev.tfvars."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Local administrator username"
  type        = string
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
  # "storage_account_type" here refers to the underlying disk tier for Azure Managed Disks.
  # It does NOT create a Storage Account resource — it is purely a performance/redundancy tier label.
  description = "OS disk storage tier (Standard_LRS | StandardSSD_LRS | Premium_LRS). Overridden per environment in dev.tfvars."
  type        = string
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB. type = number (not string) — Terraform passes this directly to the Azure API as an integer."
  type        = number
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
}

variable "data_disk_storage_account_type" {
  description = "Data disk storage type"
  type        = string
  default     = "Premium_LRS"
}

variable "maintenance_configuration_resource_id" {
  description = "ARM resource ID of the Azure Update Manager maintenance configuration used for scheduling Windows updates (Ring 1)."
  type        = string
}

variable "data_disk_lun" {
  description = "Logical Unit Number for the data disk"
  type        = number
}
