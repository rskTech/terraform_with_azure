provider "azurerm" {
  features {} # Required for the AzureRM provider
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group for storage resources."
  type        = string
  default     = "my-azure-storage-rg" # You can change this name
}

variable "location" {
  description = "The Azure region where resources will be deployed (e.g., East US, West Europe)."
  type        = string
  default     = "East US" # Choose an Azure region available in your subscription
}

variable "storage_account_name" {
  description = "The name of the Azure Storage Account to create. Must be globally unique."
  type        = string
  # Using a unique string to ensure global uniqueness for the storage account name
  default     = "mystorageaccounthz01" # IMPORTANT: CHANGE THIS TO A GLOBALLY UNIQUE NAME
}

variable "container_name" {
  description = "The name of the Blob Storage Container to create within the storage account."
  type        = string
  default     = "my-blob-container" # You can change this name
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
# A Resource Group is a logical container for your Azure resources.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Dev"
    Project     = "BlobStorage"
  }
}

# 2. Azure Storage Account
# This is the top-level resource that contains all your Azure Storage data objects.
# The `name` attribute MUST be globally unique across all of Azure.
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage (LRS) for cost-effectiveness in dev/test

  # Accepted values for account_tier: Standard, Premium
  # Accepted values for account_replication_type: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS

  tags = {
    Environment = "Dev"
    Purpose     = "DataStorage"
  }
}

# 3. Azure Blob Container
# This is the "bucket" equivalent within the Storage Account, where your blobs (files) will be stored.
resource "azurerm_storage_container" "blob_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private" # "private" (default), "blob" (read-only public), or "container" (full public)
}

