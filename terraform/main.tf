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
    resource_group_name  = "1-96ecf2f8-playground-sandbox"
    storage_account_name = "tfstatebackendstorage25"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  # AZURE ACCESS INFO
  client_id       = "c7cfd1cd-bef5-4e42-8490-f2efa86f7fa0"
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

# PUBLIC IP ADDRESS
resource "azurerm_public_ip" "vm1_public_ip" {
  name                = "vm1PublicIp"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
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
    public_ip_address_id          = azurerm_public_ip.vm1_public_ip.id
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
  network_interface_ids = [azurerm_network_interface.devops-nic.id]

  computer_name  = "daudvm"
  admin_username = var.vm_admin_username
  disable_password_authentication = true

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
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  connection {
      host = self.public_ip_address
      user = var.vm_admin_username
      type = "ssh"
      private_key = tls_private_key.devops_ssh.private_key_pem
      timeout = "4m"
      agent = false
  }
}
