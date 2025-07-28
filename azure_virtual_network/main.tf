provider "azurerm" {
  features {} # Required for the AzureRM provider
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group to create for network resources."
  type        = string
  default     = "my-azure-network-rg" # You can change this name
}

variable "location" {
  description = "The Azure region where the network resources will be deployed (e.g., East US, West Europe, Central India)."
  type        = string
  default     = "East US" # Choose an Azure region available in your subscription
}

variable "vnet_name" {
  description = "The name of the Azure Virtual Network to create."
  type        = string
  default     = "my-app-vnet" # You can change this name
}

variable "vnet_address_space" {
  description = "The IP address range for the Virtual Network in CIDR notation (e.g., [\"10.0.0.0/16\"])."
  type        = list(string)
  default     = ["10.0.0.0/16"] # This provides 65,536 private IP addresses
}

variable "subnet_name" {
  description = "The name of the subnet within the Virtual Network."
  type        = string
  default     = "default-subnet" # You can change this name
}

variable "subnet_address_prefix" {
  description = "The IP address prefix for the subnet in CIDR notation (e.g., [\"10.0.1.0/24\"])."
  type        = list(string)
  default     = ["10.0.1.0/24"] # This provides 256 IP addresses (minus Azure reserved)
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Dev"
    Project     = "Network"
  }
}

# 2. Azure Virtual Network (VNet)
# This is your private network in Azure. All resources deployed within this VNet
# can communicate with each other privately.
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = "Dev"
    Purpose     = "ApplicationNetwork"
  }
}

# 3. Azure Subnet
# Subnets allow you to segment your VNet's address space into smaller, isolated
# networks. Resources are deployed into subnets.
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

