terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.86.0, <4.0.0"
      # required for setting minimum tls to 1.3
      # but has new requirements not backward compatible
      #  version = "=4.14.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # required if upgrading to future versions of azurerm
  # such as 4.14.0
  #subscription_id = var.subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.prevent_rg_deletion
    }
  }
}
