variable "sitecore_version" {
  type = string
  description = "Supports Sitecore Version 10.3.0 to 10.4.0"
  default     = "10.4.0"
  validation {
    condition     = contains(["10.3.0","10.4.0"], lower(var.sitecore_version))
    error_message = "Supports Sitecore 10.3.0 to 10.4.0 only"
  }
}

variable "resource_group_name" {
  type = string
  description = "Resource group name for deployment."
}

variable "location" {
  type        = string
  description = "Azure region to use for deployment."
}

variable "environment" {
  type        = string
  description = "Environment code (LAB, DEV, TST, STG, PROD, DR)."
  default     = "DEV"
  validation {
    condition     = contains(["lab", "dev", "tst", "stg", "prod","dr"], lower(var.environment))
    error_message = "Must be LAB, DEV, TST, STG, PROD, DR."
  }
}

variable "client" {
  type        = string
  description = "Code name of the client. Must have 3 alphanumeric chars."
  validation {
    condition     = length(var.client) == 3
    error_message = "Must be a 3 alphanumeric code."
  }
}

variable "project" {
  type        = string
  description = "Code name of the subproject. Must have 4 digits."
  validation {
    condition     = length(var.project) == 4
    error_message = "Must be a 4 dights code."
  }
}

variable "tags" {
  description = "The tags to associate with your resources."
  type        = map

  default = {
    environment = "DEV"
    company = "Acme Corp."
  }
}

variable "windows_vm_size" {
  type= string
  description = "Azure Windows Virtual Machine Size"
  default= "Standard_B2ms"
}

variable "admin_username" {
  type = string
  description = "VM Admin Username [Note: Password would be auto generated]"
  default = "adminuser"
}

variable "vnet_address_space" {
  type = string
  description = "Virtual Network Address Space in CIDR format"
  default = "10.0.0.0/16"
}

variable "subnet_address_space" {
  type = string
  description = "Subnet Address Space in CIDR format"
  default = "10.0.2.0/24"
}

variable "sas_token" {
  type = string
  description = "SAS Token for accessing Azure Storage"
  default = ""
  
}