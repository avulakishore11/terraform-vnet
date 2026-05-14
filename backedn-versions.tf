# fmt fix: terraform fmt requires 2-space indentation throughout (was 4-space).
# fmt fix: all = signs within a block must align to the longest key.
#          Here storage_account_name (20 chars) sets the column; key (3 chars) and
#          use_azuread_auth (16 chars) were under-padded and failed terraform fmt -check.
terraform {
  backend "azurerm" {
    resource_group_name  = "kaseya-orgchat"        # replace with your resource group name where the storage account is located
    storage_account_name = "saeushrfile"       # replace with your storage account name
    container_name       = "tfstate"            # replace with your container name
    key                  = "dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}
