terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "2.0.0-preview3"
    }
    random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
  }
  skip_provider_registration = true
}

module "scsolr_naming" {
  source      = "./modules/naming"
  client      = var.client
  location    = var.location
  project     = var.project
  environment = var.environment
}

resource "azurecaf_name" "this" {
  resource_types = ["azurerm_virtual_network", "azurerm_subnet", "azurerm_public_ip", "azurerm_network_security_group", "azurerm_network_interface", "azurerm_windows_virtual_machine"]
  # prefixes      = module.scsolr_naming.resource_prefixes
  suffixes = module.scsolr_naming.resource_prefixes
  # use_slug      = false
  clean_input = true
  separator   = "-"
}

# resource "azurerm_resource_group" "this" {
#   name = var.resource_group_name
#   location = var.location
# }

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Create virtual network
resource "azurerm_virtual_network" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  name = azurecaf_name.this.results.azurerm_virtual_network
  address_space = ["10.0.0.0/16"]
  resource_group_name = data.azurerm_resource_group.this.name
  location = var.location
  tags = var.tags
}

# Create subnet
resource "azurerm_subnet" "this" {
  name = azurecaf_name.this.results.azurerm_subnet
  resource_group_name = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes = ["10.0.2.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  name = azurecaf_name.this.results.azurerm_public_ip
  resource_group_name = data.azurerm_resource_group.this.name
  location = var.location
  allocation_method = "Static"
  sku = "Standard"
  tags = var.tags
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  name                = azurecaf_name.this.results.azurerm_network_security_group
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.location

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "secureweb"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "solr"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8983"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  name= azurecaf_name.this.results.azurerm_network_interface
  resource_group_name = data.azurerm_resource_group.this.name
  location = var.location

  ip_configuration {
    name = "ipconfig"
    subnet_id = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.this.id
  }
  tags = var.tags
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# Generate Random Password for Admin User
resource "random_string" "admin_password" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  length           = 16
  override_special = "$!#"
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  name                = azurecaf_name.this.results.azurerm_windows_virtual_machine
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.location

  size = var.windows_vm_size
  admin_username = var.admin_username
  admin_password = random_string.admin_password.result

  # license_type = "Windows_Server"

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2022-Datacenter"
    version = "latest"
  }
  tags = var.tags
}

resource "azurerm_virtual_machine_extension" "this" {
  count = length(data.azurerm_resource_group.this.id) > 0 ? 1 : 0
  name = "${azurerm_windows_virtual_machine.this.name}-ext"
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "fileUris":["https://raw.githubusercontent.com/codeblitzmaster/terraform-azurerm-sitecoresolr/main/Artifacts/Install-Solr.ps1"],
    "commandToExecute": "powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -File Install-Solr.ps1 -SitecoreVersion ${var.sitecore_version}"
  }
  SETTINGS
}