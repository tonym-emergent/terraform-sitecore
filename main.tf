

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

# Data objects (VNet, Subnet, NSG)'

data "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}
data "azurerm_subnet" "this" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.this.name
}

/*
# Create public IP
resource "azurerm_public_ip" "this" {
  name = azurecaf_name.this.results.azurerm_public_ip
  resource_group_name = var.resource_group_name
  location = var.location
  allocation_method = "Static"
  sku = "Standard"
  tags = var.tags
}
*/

# Create Network Security Group and rules
resource "azurerm_network_security_group" "this" {
  name                = azurecaf_name.this.results.azurerm_network_security_group
  resource_group_name = var.resource_group_name
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
  name= azurecaf_name.this.results.azurerm_network_interface
  resource_group_name = var.resource_group_name
  location = var.location

  ip_configuration {
    name = "ipconfig"
    subnet_id = data.azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id = azurerm_public_ip.this.id
  }
  tags = var.tags
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# Generate Random Password for Admin User
resource "random_string" "admin_password" {
  length           = 16
  override_special = "$!#"
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "this" {
  name                = azurecaf_name.this.results.azurerm_windows_virtual_machine
  resource_group_name = var.resource_group_name
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


# Extensions to run a PowerShell scripts on the VM, in order of dependencies
resource "azurerm_virtual_machine_extension" "configure_server" {
  name                 = "configure_server"
  virtual_machine_id   = azurerm_windows_virtual_machine.this.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/tonym-emergent/terraform-sitecore/main/install.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File install.ps1"
    }
  SETTINGS
}
