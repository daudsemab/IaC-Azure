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
    resource_group_name  = "1-4280e488-playground-sandbox"
    storage_account_name = "tfstatebackendstorage24"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  # AZURE ACCESS INFO
  client_id       = "a1ffea1c-8f45-44db-b6fe-81b07063da71"
  client_secret   = var.CLIENT_ACCESS
  tenant_id       = "84f1e4ea-8554-43e1-8709-f0b8589ea118"
  subscription_id = "9734ed68-621d-47ed-babd-269110dbacb1"
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

# NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "devops-nsg" {
    name                = "nsg1"
    location            = var.resource_group_location
    resource_group_name = var.resource_group_name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
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

# NIC AND NSG CONNECTION
resource "azurerm_network_interface_security_group_association" "network-connection" {
    network_interface_id      = azurerm_network_interface.devops-nic.id
    network_security_group_id = azurerm_network_security_group.devops-nsg.id
}

# TLS KEY
resource "tls_private_key" "devops_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# PRIVATE KEY FILE
resource "local_file" "private_key" {
  content  = tls_private_key.devops_ssh.private_key_pem
  filename = "${path.module}/id_rsa"
}

# PUBLIC KEY FILE
resource "local_file" "public_key" {
  content  = tls_private_key.devops_ssh.public_key_openssh
  filename = "${path.module}/id_rsa.pub" 
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
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
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

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y software-properties-common python3-pip python3-dev python3-setuptools python3-venv python3-jinja2 python3-yaml python3-httplib2 sshpass python3-cryptography",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible"
    ]
  }


  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${azurerm_linux_virtual_machine.devops-vm.public_ip_address}, -u ${var.vm_admin_username} --private-key ${path.module}/id_rsa_key ./../ansible/playbook.yml"
  }
}
