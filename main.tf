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
    resource_group_name   = "rg-tf-state"
    storage_account_name  = "terrastatesa"
    container_name        = "tfstate"
    key                   = "vnet.tfstate"
  }
}

provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "rg" {
  name     = "terraform-rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = "eastus"
  resource_group_name = "terraform-rg"
  address_space       = ["10.0.0.0/32"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = "terraform-rg"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}
