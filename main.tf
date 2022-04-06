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
  location = "eastus"
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

  tags = {
    environment = "Production"
    faculdade = "Impacta"
  }
}