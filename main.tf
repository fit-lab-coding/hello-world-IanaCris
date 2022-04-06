terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {  
  features {}
}

resource "azurerm_resource_group" "rg-infra" {
  name     = "infracloudaz"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "vnet-infra" {
  name                = "vnetinfracloud"
  location            = azurerm_resource_group.rg-infra.location
  resource_group_name = azurerm_resource_group.rg-infra.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    faculdade = "Impacta"
  }
}

resource "azurerm_subnet" "subnet-infra" {
  name                 = "subnetinfracloud"
  resource_group_name  = azurerm_resource_group.rg-infra.name
  virtual_network_name = azurerm_virtual_network.vnet-infra.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ip-infra" {
  name                    = "publicipinfracloud"
  location                = azurerm_resource_group.rg-infra.location
  resource_group_name     = azurerm_resource_group.rg-infra.name
  allocation_method       = "Static"

  tags = {
    faculdade = "Impacta"
  }
}

resource "azurerm_network_security_group" "nsg-infra" {
  name                = "nsginfracloud"
  location            = azurerm_resource_group.rg-infra.location
  resource_group_name = azurerm_resource_group.rg-infra.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
    faculdade = "Impacta"
  }
}

resource "azurerm_network_interface" "nic-infra" {
  name                = "nicinfracloud"
  location            = azurerm_resource_group.rg-infra.location
  resource_group_name = azurerm_resource_group.rg-infra.name

  ip_configuration {
    name                          = "nic-ip"
    subnet_id                     = azurerm_subnet.subnet-infra.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-infra.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-infra" {
  network_interface_id      = azurerm_network_interface.nic-infra.id
  network_security_group_id = azurerm_network_security_group.nsg-infra.id
}

resource "azurerm_storage_account" "sa-infra" {
  name                     = "sainfracloud"
  resource_group_name      = azurerm_resource_group.rg-infra.name
  location                 = azurerm_resource_group.rg-infra.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
    faculdade = "Impacta"
  }
}

resource "azurerm_linux_virtual_machine" "vm-infra" {
  name                = "vminfracloud"
  resource_group_name = azurerm_resource_group.rg-infra.name
  location            = azurerm_resource_group.rg-infra.location
  size                = "Standard_E2bs_v5"
  network_interface_ids = [
    azurerm_network_interface.nic-infra.id,
  ]

  admin_username      = "adminuser"
  admin_password      = "Pass1234word?"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name     = "mydisk"
    caching  = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.sa-infra.primary_blob_endpoint
  }
}

data "azurerm_public_ip" "publicip-infra-data" {
  name = azurerm_public_ip.ip-infra.name
  resource_group_name = azurerm_resource_group.rg-infra.name
}
resource "null_resource" "install-webserver" {
  connection {
    type = "ssh"
    host = data.azurerm_public_ip.publicip-infra-data.ip_address
    user = "adminuser"
    password = "Pass1234word?"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2"
    ]
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm-infra
  ]
}