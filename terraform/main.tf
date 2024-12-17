########## Before Running This File, Make Sure Storage Account and Container are aleady Created with Same Names ##########

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }

  # BACKEND STORAGE FOR TERRAFORM STATE
  backend "azurerm" {
    resource_group_name  = "1-9ddb1d1d-playground-sandbox"
    storage_account_name = "tfstatebackendstorage23"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  # AZURE ACCESS INFO
  client_id       = "28fcb13b-3953-41d6-82bd-056537140b90"
  client_secret   = var.CLIENT_ACCESS
  tenant_id       = "84f1e4ea-8554-43e1-8709-f0b8589ea118"
  subscription_id = "80ea84e8-afce-4851-928a-9e2219724c69"
  resource_provider_registrations = "none"
}

# VIRTUAL NETWORK
resource "azurerm_virtual_network" "devops-vnet" {
  name                = "devops-network"
  address_space       = var.vnet_address_space
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

# SUBNET
resource "azurerm_subnet" "devops-subnet" {
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.devops-vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# NETWORK INTERFACE CARD
resource "azurerm_network_interface" "devops-nic" {
  name                = "dev-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# TLS KEY
resource "tls_private_key" "devops_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# VIRTUAL MACHINE
resource "azurerm_linux_virtual_machine" "devops-vm" {
  name                = "vm1"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = "Standard_B2s"
  admin_username      = var.vm_admin_username

  network_interface_ids = [azurerm_network_interface.devops-nic.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.devops_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${azurerm_linux_virtual_machine.devops-vm.public_ip_address}, -u ${var.vm_admin_username} --private-key ${tls_private_key.devops_ssh.private_key_pem} ./../ansible/playbook.yml"
  }
}
