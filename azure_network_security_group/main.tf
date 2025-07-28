provider "azurerm" {
  features {} # Required for the AzureRM provider
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group to create for the NSG."
  type        = string
  default     = "my-azure-nsg-rg" # You can change this name
}

variable "location" {
  description = "The Azure region where the NSG will be deployed (e.g., East US, West Europe, Central India)."
  type        = string
  default     = "East US" # Choose an Azure region available in your subscription
}

variable "nsg_name" {
  description = "The name of the Network Security Group to create."
  type        = string
  default     = "my-application-nsg" # You can change this name
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Dev"
    Project     = "NetworkSecurity"
  }
}

# 2. Azure Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = "Dev"
    Purpose     = "VMTrafficControl"
  }

  # --- Security Rules ---
  # Rules define what traffic is allowed or denied.
  # Priorities determine the order of evaluation (lower number = higher precedence).
  # Direction: Inbound or Outbound
  # Access: Allow or Deny
  # Protocol: Tcp, Udp, *, Icmp
  # Source/Destination Port Range: e.g., "22", "80-8080", "*"
  # Source/Destination Address Prefix: e.g., "10.0.0.0/24", "Internet", "VirtualNetwork", "*"

  # Rule 1: Allow SSH (Port 22) Inbound
  # This is a common rule to allow remote access to Linux VMs.
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100 # High precedence
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"      # Any source port
    destination_port_range     = "22"     # SSH standard port
    source_address_prefix      = "*"      # Allow from any IP (for learning; restrict in production!)
    destination_address_prefix = "*"      # To any destination IP
    description                = "Allow inbound SSH traffic"
  }

  # Rule 2: Allow HTTP (Port 80) Inbound
  # This rule allows web traffic if you're running a web server.
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110 # Slightly lower precedence than SSH
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow inbound HTTP traffic"
  }

  # Rule 3: Allow All Outbound Traffic (Default behavior, often explicitly defined)
  # This rule explicitly allows all traffic originating from resources associated with this NSG.
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 300 # Lower precedence, after specific inbound rules
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow all outbound traffic"
  }
}

