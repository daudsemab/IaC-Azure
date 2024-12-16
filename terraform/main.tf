terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
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