terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

#terrafrom remote backend storage

terraform {
  backend "azurerm" {
    resource_group_name   = "bicep-rg"
    storage_account_name  = "terraformsa16nf"
    container_name        = "terraform-state-container"
  }
}

provider "azurerm" {
  features {}

}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = "eastus"
  resource_group_name = "bicep-rg"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = "bicep-rg"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
