provider "azurerm" {
  features {} # Required for the AzureRM provider
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group."
  type        = string
  default     = "my-autoscaled-vmss-rg"
}

variable "location" {
  description = "The Azure region where resources will be deployed (e.g., East US, West Europe)."
  type        = string
  default     = "East US" # Change if needed, try 'West US' or 'North Europe' if 'East US' has quota issues.
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
  default     = "my-vmss-vnet"
}

variable "subnet_name" {
  description = "The name of the Subnet within the Virtual Network."
  type        = string
  default     = "my-vmss-subnet"
}

variable "vmss_name" {
  description = "The name of the Virtual Machine Scale Set."
  type        = string
  default     = "my-autoscaled-app"
}

variable "lb_public_ip_name" {
  description = "The name of the Public IP for the Load Balancer."
  type        = string
  default     = "my-vmss-lb-public-ip"
}

variable "lb_name" {
  description = "The name of the Load Balancer."
  type        = string
  default     = "my-vmss-lb"
}

variable "nsg_name" {
  description = "The name of the Network Security Group for the VMSS."
  type        = string
  default     = "my-vmss-nsg"
}

variable "admin_username" {
  description = "The administrator username for the Linux VMs in the Scale Set."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "The file path to your SSH public key (e.g., ~/.ssh/id_rsa.pub or ./id_rsa.pub)."
  type        = string
  # IMPORTANT: Ensure 'id_rsa.pub' is in the same directory as this main.tf file.
  default     = "./id_ed25519.pub"
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Dev"
    Project     = "VMSSAutoscale"
  }
}

# 2. Azure Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Azure Subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Network Security Group (NSG) for VMSS instances
# This NSG will be associated with the network interfaces of the VMSS instances.
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
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
    source_address_prefix      = "*" # IMPORTANT: Restrict this to your specific IP in production!
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 5. Associate NSG with the Subnet
# This ensures all new NICs in this subnet automatically inherit these NSG rules.
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 6. Public IP Address for the Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = var.lb_public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU required for Standard Load Balancer
}

# 7. Azure Load Balancer
resource "azurerm_lb" "lb" {
  name                = var.lb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard" # Standard SKU recommended for VMSS

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontend"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

# 8. Load Balancer Backend Address Pool (for VMSS instances)
resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  name            = "BackendPool"
  loadbalancer_id = azurerm_lb.lb.id
}

# 9. Load Balancer Health Probe
resource "azurerm_lb_probe" "lb_probe" {
  name            = "HttpProbe"
  protocol        = "Tcp"
  port            = 80 # Assuming your app listens on port 80
  interval_in_seconds = 5
  number_of_probes = 2
  loadbalancer_id = azurerm_lb.lb.id
}

# 10. Load Balancing Rule (HTTP traffic to VMSS instances)
resource "azurerm_lb_rule" "lb_rule_http" {
  name                          = "HTTPRule"
  protocol                      = "Tcp"
  frontend_port                 = 80
  backend_port                  = 80
  frontend_ip_configuration_name = "LoadBalancerFrontend"
  probe_id                      = azurerm_lb_probe.lb_probe.id
  loadbalancer_id               = azurerm_lb.lb.id
  backend_address_pool_ids      = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
}

# 11. Virtual Machine Scale Set (VMSS)
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B1s" # Very small, cost-effective VM size for learning/testing
  admin_username      = var.admin_username
  instances           = 2 # Start with 2 instances

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path) # Reads the content of your SSH public key file
  }
  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-focal" # Updated offer name
  sku       = "20_04-lts"                     # Corresponding SKU for this offer
  version   = "latest"
}

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "myvmssnic"
    primary = true
    ip_configuration {
      name                          = "internal"
      primary                       = true
      subnet_id                     = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
      # NSG association is done at the subnet level via `azurerm_subnet_network_security_group_association`
    }
  }

  # Ensure the VMSS is provisioned before configuring autoscale
  depends_on = [
    azurerm_lb.lb,
    azurerm_lb_backend_address_pool.lb_backend_pool,
    azurerm_lb_probe.lb_probe,
    azurerm_lb_rule.lb_rule_http
  ]
}

# 12. Autoscale Setting for the VMSS
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "Default"

    capacity {
      default = 2  # Start with 2 instances
      minimum = 1  # Minimum 1 instance (always keep one running)
      maximum = 5  # Maximum 5 instances (scale up to 5)
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"  # 1 minute aggregation
        statistic          = "Average"
        time_window        = "PT5M"  # Evaluate over 5 minutes
        operator           = "GreaterThan"
        threshold          = 75    # If average CPU > 75%
        time_aggregation   = "Average" # REQUIRED: How to aggregate the metric data over the time_window
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1     # Increase instance count by 1
        cooldown  = "PT5M" # Wait 5 minutes before another scale-out action
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        operator           = "LessThan"
        threshold          = 25    # If average CPU < 25%
        time_aggregation   = "Average" # REQUIRED: How to aggregate the metric data over the time_window
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1     # Decrease instance count by 1
        cooldown  = "PT5M" # Wait 5 minutes before another scale-in action
      }
    }
  }

  tags = {
    Environment = "Dev"
    Component   = "Autoscale"
  }
}

output "load_balancer_public_ip" {
  description = "The public IP address of the Load Balancer (access point for your application)."
  value       = azurerm_public_ip.lb_public_ip.ip_address
}

output "vmss_name" {
  description = "The name of the Virtual Machine Scale Set."
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "autoscale_setting_name" {
  description = "The name of the Autoscale Setting configured for the VMSS."
  value       = azurerm_monitor_autoscale_setting.vmss_autoscale.name
}

output "ssh_info" {
  description = "Connect to a VMSS instance (example for one instance). You will need to get individual VM IP from Azure portal."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.lb_public_ip.ip_address} (Note: Load Balancer IP. You may need to SSH to individual VMSS instances for specific tasks. Find their IPs in Azure portal under VMSS -> Instances)"
}

