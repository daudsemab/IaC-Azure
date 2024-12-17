output "vm1_private_ip" {
  value = azurerm_linux_virtual_machine.devops-vm.private_ip_address
}

output "vm1_public_ip" {
  value       = azurerm_linux_virtual_machine.devops-vm.public_ip_address
}

output "tls_private_key" { 
    value = tls_private_key.devops_ssh.private_key_pem 
    sensitive = true
}