terraform {
    backend "azurerm" {
        resource_group_name  = "rg-tf-state"        # replace with your resource group name where the storage account is located
        storage_account_name = "terrastatesa"       # replace with your storage account name
        container_name       = "tfstate"            # replace with your container name
        key                  = "windows-vm.tfstate" # replace with your desired state file name
    }
}
