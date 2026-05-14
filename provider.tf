terraform {
  # tflint terraform_required_version: pin the minimum Terraform CLI version so
  # all environments (local, CI, team members) use a compatible release.
  # >= 1.3.0 is required for optional() in variable type constraints.
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
