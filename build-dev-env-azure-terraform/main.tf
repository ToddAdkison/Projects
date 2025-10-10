terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"

    }
  }
}
provider "azurerm" {
  subscription_id = "c8413d4c-b5ee-4796-ba39-c389f68ed45c"
  features {}
}

resource "azurerm_resource_group" "rg-linuxvm-scus-001" {
  name     = "rg-linuxvm-scus-001"
  location = "South Central US"
  tags = {
    env    = "dev"
    region = "southcentralus"

  }
}

resource "azurerm_virtual_network" "vnet-linuxvm-scus-001" {
  name                = "vnet-linuxvm-scus-001"
  location            = azurerm_resource_group.rg-linuxvm-scus-001.location
  resource_group_name = azurerm_resource_group.rg-linuxvm-scus-001.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    env    = "dev"
    region = "southcentralus"
  }
}

resource "azurerm_subnet" "snet-linuxvm-scus-001" {
  name                 = "snet-linuxvm-scus-001"
  resource_group_name  = azurerm_resource_group.rg-linuxvm-scus-001.name
  virtual_network_name = azurerm_virtual_network.vnet-linuxvm-scus-001.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg-linuxvm-scus-001" {
  name                = "nsg-linuxvm-scus-001"
  location            = azurerm_resource_group.rg-linuxvm-scus-001.location
  resource_group_name = azurerm_resource_group.rg-linuxvm-scus-001.name

  tags = {
    env    = "dev"
    region = "southcentralus"
  }
}

resource "azurerm_network_security_rule" "nsgsr-linuxvm-scus-001" {
  name                        = "nsgsr-linuxvm-scus-001-allow-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-linuxvm-scus-001.name
  network_security_group_name = azurerm_network_security_group.nsg-linuxvm-scus-001.name
}

resource "azurerm_subnet_network_security_group_association" "sga-linuxvm-scus-001" {
  subnet_id                 = azurerm_subnet.snet-linuxvm-scus-001.id
  network_security_group_id = azurerm_network_security_group.nsg-linuxvm-scus-001.id
}

resource "azurerm_public_ip" "pip-linuxvm-scus-001" {
  name                = "pip-linuxvm-scus-001"
  resource_group_name = azurerm_resource_group.rg-linuxvm-scus-001.name
  location            = azurerm_resource_group.rg-linuxvm-scus-001.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = {
    env    = "dev"
    region = "southcentralus"
  }
}

resource "azurerm_network_interface" "nic-linuxvm-scus-001" {
  name                = "nic-linuxvm-scus-001"
  location            = azurerm_resource_group.rg-linuxvm-scus-001.location
  resource_group_name = azurerm_resource_group.rg-linuxvm-scus-001.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-linuxvm-scus-001.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-linuxvm-scus-001.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-linuxvm-scus-001" {
  name                = "vm-linuxvm-scus-001"
  resource_group_name = azurerm_resource_group.rg-linuxvm-scus-001.name
  location            = azurerm_resource_group.rg-linuxvm-scus-001.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic-linuxvm-scus-001.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azlinuxvm.pub")
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
}