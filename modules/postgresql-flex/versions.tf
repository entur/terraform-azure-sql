terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.57"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.12.0"
    }
  }
  required_version = ">= 0.13"
}