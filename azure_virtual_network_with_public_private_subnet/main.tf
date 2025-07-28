provider "azurerm" {
  features {} # Required for the AzureRM provider
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group for network resources."
  type        = string
  default     = "my-network-rg"
}

variable "location" {
  description = "The Azure region where resources will be deployed (e.g., East US, West Europe)."
  type        = string
  default     = "East US" # Choose an Azure region available in your subscription
}

variable "vnet_name" {
  description = "The name of the Azure Virtual Network."
  type        = string
  default     = "my-secure-vnet"
}

variable "vnet_address_space" {
  description = "The IP address range for the Virtual Network in CIDR notation."
  type        = list(string)
  default     = ["10.0.0.0/16"] # Provides 65,536 private IP addresses
}

variable "public_subnet_name" {
  description = "The name of the public subnet."
  type        = string
  default     = "public-subnet"
}

variable "public_subnet_prefix" {
  description = "The IP address prefix for the public subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"] # Provides 256 IP addresses
}

variable "private_subnet_name" {
  description = "The name of the private subnet."
  type        = string
  default     = "private-subnet"
}

variable "private_subnet_prefix" {
  description = "The IP address prefix for the private subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"] # Provides 256 IP addresses
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Dev"
    Project     = "NetworkSegmentation"
  }
}

# 2. Azure Virtual Network (VNet)
# This is your isolated private network in Azure.
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

# 3. Public Subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = var.public_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.public_subnet_prefix
}

# 4. Private Subnet
# This subnet is intended for backend resources that should not be directly accessible from the internet.
resource "azurerm_subnet" "private_subnet" {
  name                 = var.private_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.private_subnet_prefix
}

# 5. NSG for Public Subnet
# Rules for public-facing resources (e.g., allowing SSH, HTTP/S).
resource "azurerm_network_security_group" "public_nsg" {
  name                = "${var.public_subnet_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet" # Restrict to specific IPs in production!
    destination_address_prefix = "*"
    description                = "Allow inbound SSH traffic"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Allow inbound HTTP traffic"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Allow inbound HTTPS traffic"
  }
}

# 6. NSG for Private Subnet
# Rules for private backend resources (e.g., only allowing traffic from the VNet).
resource "azurerm_network_security_group" "private_nsg" {
  name                = "${var.private_subnet_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork" # Allow only from within the VNet
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow inbound traffic from VNet"
  }

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200 # Higher than default deny, ensures explicit deny
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet" # Explicitly deny inbound from Internet
    destination_address_prefix = "*"
    description                = "Deny inbound traffic from Internet"
  }
}

# 7. Associate NSG with Public Subnet
resource "azurerm_subnet_network_security_group_association" "public_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# 8. Associate NSG with Private Subnet
resource "azurerm_subnet_network_security_group_association" "private_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

