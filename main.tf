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