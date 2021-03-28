terraform {
  required_version = "~> 0.14.0"
  required_providers {
    template = "~> 2.2"
    null     = "~> 3.1"
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }    
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}