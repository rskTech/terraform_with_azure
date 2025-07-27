# Configure the Azure Provider
# This tells Terraform to use the Azure Resource Manager provider.
# Make sure you're logged into Azure via the Azure CLI (`az login`) before running this script,
# as Terraform will use your existing credentials.
provider "azurerm" {
  features {} # Required for the AzureRM provider
}

# --- Input Variables ---
# These variables let you easily customize your VM and its resources.
# You can change these default values or provide them when you run `terraform apply`.

variable "resource_group_name" {
  description = "The name of the Azure Resource Group to create."
  type        = string
  default     = "my-first-azure-vm-rg"
}

variable "location" {
  description = "The Azure region where all resources will be deployed (e.g., East US, West Europe)."
  type        = string
  default     = "East US"
}

variable "vm_name" {
  description = "The name of your new Linux Virtual Machine."
  type        = string
  default     = "my-first-linux-vm"
}

variable "admin_username" {
  description = "The username for the administrator account on your VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "The file path to your SSH public key (e.g., ~/.ssh/id_rsa.pub or ./id_rsa.pub)."
  type        = string
  # IMPORTANT: Ensure this path points to your actual SSH public key.
  # If you don't have one, generate it first using `ssh-keygen -t rsa -b 4096`.
  default     = "./id_ed25519.pub"
}

# --- Azure Resource Creation ---

# 1. Azure Resource Group
# A Resource Group is a logical container for your Azure resources.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Azure Virtual Network (VNet)
# A VNet is your isolated private network in Azure.
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"] # Define the IP address range for your VNet
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Subnet
# A Subnet is a segment within your VNet's IP address space.
resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. Public IP Address
# This IP allows your VM to be reachable from the internet (for SSH access).
#resource "azurerm_public_ip" "public_ip" {
#  name                = "${var.vm_name}-public-ip"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#  allocation_method   = "Dynamic" # Dynamic IP (changes if VM is stopped/started)
#  sku                 = "Basic"   # Basic SKU is generally sufficient for learning
#}

# 5. Network Security Group (NSG)
# An NSG acts as a virtual firewall, controlling traffic to and from your VM.
# This is crucial for allowing SSH access.
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # NSG Rule: Allow SSH (Port 22) Inbound
  # This rule is essential to connect to your Linux VM via SSH.
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100 # Lower priority number means higher precedence
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*" # Any source port
    destination_port_range     = "22" # SSH standard port
    source_address_prefix      = "*" # Allow SSH from any IP (for learning; restrict in production!)
    destination_address_prefix = "*" # To any destination IP
  }
}

# 6. Network Interface (NIC)
# The NIC connects your VM to the virtual network.
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # The NSG association will now be handled by a separate resource below.

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# 6a. Network Interface Security Group Association
# This resource explicitly links the Network Interface (NIC) to the Network Security Group (NSG).
# This is an alternative way to associate an NSG if the direct argument on the NIC resource isn't working.
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# 7. Linux Virtual Machine
# This is the definition of your actual virtual machine.
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" # Very small VM size, good for learning and low cost
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # Operating System Disk
  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Standard HDD, locally redundant storage
  }

  # Source Image for the OS
  # This specifies that we want to use Ubuntu Server 20.04 LTS (Long Term Support).
  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-focal" # Updated offer name
  sku       = "20_04-lts"                     # Corresponding SKU for this offer
  version   = "latest"
}

  # SSH Public Key for Authentication
  # Terraform will inject this key into your VM, allowing you to log in securely.
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path) # Reads the content of your SSH public key file
  }
}

# --- Outputs ---

#output "public_ip_address" {
#  description = "The public IP address of your Linux Virtual Machine."
#  value       = azurerm_public_ip.public_ip.ip_address
#}

#output "ssh_command" {
#  description = "Use this command to connect to your Linux Virtual Machine via SSH."
#  value       = "ssh ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
#}

