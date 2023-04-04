terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
  }
  skip_provider_registration = true
}

module "sitecoresolr" {
  source  = "codeblitzmaster/sitecoresolr/azurerm"
  version = "1.0.1-beta"
  # insert the 5 required variables here
    client = "ACM"
    admin_username = "adminuser"
    environment = "STG"
    location = "East US"
    resource_group_name = "sitecore-rg"
    project = "site"
    sitecore_version = "10.3.0"
}