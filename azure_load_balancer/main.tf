provider "azurerm" {
  features {} # Required for the AzureRM provider
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group for load balancer and network resources."
  type        = string
  default     = "my-azure-lb-rg" # You can change this name
}

variable "location" {
  description = "The Azure region where resources will be deployed (e.g., East US, West Europe)."
  type        = string
  default     = "East US" # Choose an Azure region available in your subscription
}

variable "vnet_name" {
  description = "The name of the Azure Virtual Network."
  type        = string
  default     = "my-lb-vnet"
}

variable "vnet_address_space" {
  description = "The IP address range for the Virtual Network in CIDR notation."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "backend_subnet_name" {
  description = "The name of the subnet where backend VMs will reside."
  type        = string
  default     = "backend-subnet"
}

variable "backend_subnet_prefix" {
  description = "The IP address prefix for the backend subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "load_balancer_name" {
  description = "The name of the Azure Load Balancer."
  type        = string
  default     = "my-app-lb"
}

variable "public_ip_name" {
  description = "The name of the Public IP Address for the Load Balancer frontend."
  type        = string
  default     = "my-lb-public-ip"
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
# A Resource Group is a logical container for your Azure resources.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Dev"
    Project     = "LoadBalancing"
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
    Purpose     = "LBNetwork"
  }
}

# 3. Backend Subnet
# This subnet will host the backend virtual machines that the Load Balancer distributes traffic to.
resource "azurerm_subnet" "backend_subnet" {
  name                 = var.backend_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.backend_subnet_prefix
}

# 4. Public IP Address for the Load Balancer
# This public IP will be the frontend IP of the Load Balancer, accessible from the internet.
resource "azurerm_public_ip" "lb_public_ip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU is required for Standard Load Balancer
}

# 5. Azure Load Balancer
# This resource defines the Azure Load Balancer itself.
resource "azurerm_lb" "lb" {
  name                = var.load_balancer_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard" # Standard SKU is recommended for production workloads

  # Frontend IP configuration: The public IP address where traffic arrives.
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontend"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }

  tags = {
    Environment = "Dev"
    Component   = "LoadBalancer"
  }
}

# 6. Load Balancer Backend Address Pool
# This pool defines the group of IP addresses (typically NICs of VMs) that will receive the load-balanced traffic.
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "BackendPool"
  loadbalancer_id = azurerm_lb.lb.id
}

# 7. Load Balancer Health Probe
# A health probe is used to monitor the health of your backend instances.
# Traffic is only sent to instances that pass the health probe.
resource "azurerm_lb_probe" "health_probe" {
  name            = "HttpHealthProbe"
  protocol        = "Tcp" # Or "Http" if you have a specific path to check
  port            = 80    # Port on backend instances to check
  interval_in_seconds = 5 # How often to probe
  number_of_probes = 2    # Number of consecutive successful probes required to mark healthy
  loadbalancer_id = azurerm_lb.lb.id
}

# 8. Load Balancing Rule
# This rule defines how incoming traffic from the frontend IP is distributed to the backend pool.
resource "azurerm_lb_rule" "lb_rule_http" {
  name                          = "HTTPRule"
  protocol                      = "Tcp"
  frontend_port                 = 80    # Port the Load Balancer listens on
  backend_port                  = 80    # Port on backend instances to send traffic to
  frontend_ip_configuration_name = "LoadBalancerFrontend"
  probe_id                      = azurerm_lb_probe.health_probe.id
  loadbalancer_id               = azurerm_lb.lb.id
  backend_address_pool_ids      = [azurerm_lb_backend_address_pool.backend_pool.id]
}

