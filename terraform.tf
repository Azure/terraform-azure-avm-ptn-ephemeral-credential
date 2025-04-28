terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.1, < 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.1, < 1.0"
    }
  }
}
