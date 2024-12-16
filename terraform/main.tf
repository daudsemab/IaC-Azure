terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }

  backend "azurerm" { # Step-2 to setup remote state.
    resource_group_name  = "1-811d974d-playground-sandbox"
    storage_account_name = "tfstatebackendstorage11"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  client_id       = "8692efc6-9195-4566-856f-e2a0ddbc3478"
  client_secret   = var.CLIENT_ACCESS
  tenant_id       = "84f1e4ea-8554-43e1-8709-f0b8589ea118"
  subscription_id = "28e1e42a-4438-4c30-9a5f-7d7b488fd883"
  resource_provider_registrations = "none"
}


resource "azurerm_storage_account" "tfstate" { # Step-1 to setup remote state.
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.resource_group_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    environment = "devops"
  }
}

resource "azurerm_storage_container" "tfstate" { # Step-1 to setup remote state.
  name                  = var.storage_container_name
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}


resource "azurerm_virtual_network" "devops-vnet" { # Virtual Network
  name                = "devops-network"
  address_space       = var.vnet_address_space
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "devops-subnet" { # Subnet
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.devops-vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_network_interface" "devops-nic" { # NiC
  name                = "dev-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "tls_private_key" "devops_ssh" { # SSH Key Generation
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_linux_virtual_machine" "devops-vm" { # Virtual Machine
  name                = "vm1"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = "Standard_B2s"
  admin_username      = "daudsemab"
  network_interface_ids = [
    azurerm_network_interface.devops-nic.id,
  ]

  admin_ssh_key {
    username   = "daudsemab"
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
}