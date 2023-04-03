locals {
  location_map_codes = {
    "East US" = "eastus"
    "East US 2" = "eastus2"
    "South Central US" = "southcentralus"
    "West US" = "westus"
    "West US 2" = "westus2"
    "West US 3" = "westus3"
    "Australia East" = "australiaeast"
    "Southeast Asia" = "southeastasia"
    "North Europe" = "northeurope"
  }

  location_safe = lower(local.location_map_codes[var.location])
  project_safe          = lower(var.project)
}