output "vm_ip" {
  value = azurerm_windows_virtual_machine.this.public_ip_address
  description = "Virtual Machine Public IP"
}

output "admin_username" {
  value = var.admin_username
  description = "Admin Username"
}

output "admin_password" {
  value = azurerm_windows_virtual_machine.this.admin_password
  description = "Admin Password"
  sensitive = true
}