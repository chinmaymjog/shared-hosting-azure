terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.17"
    }
  }
}

provider "azurerm" {
  features {
    netapp {
      delete_backups_on_backup_vault_destroy = true
      prevent_volume_destruction             = false
    }
  }
}
