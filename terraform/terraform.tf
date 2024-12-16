terraform {
provider "azurerm" {
  features {}
}
  #   backend "azurerm" { # Step-2 to setup remote state.
  #     resource_group_name  = var.resource_group_name
  #     storage_account_name = var.storage_account_name
  #     container_name       = var.storage_container_name
  #     key                  = "terraform.tfstate"
  # }
}
