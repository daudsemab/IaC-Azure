output "vm1_private_ip" {
  value = data.azurerm_linux_virtual_machine.devops-vm.private_ip_address
}