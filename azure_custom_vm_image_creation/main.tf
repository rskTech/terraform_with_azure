provider "azurerm" {
  features {} # Required for the AzureRM provider
}
variable "resource_group_name" {
  description = "The name of the Azure Resource Group for all resources."
  type        = string
  default     = "my-custom-image-rg"
}

variable "location" {
  description = "The Azure region where resources will be deployed (e.g., East US, West Europe)."
  type        = string
  default     = "East US" # Choose an Azure region available in your subscription
}

variable "vm_name" {
  description = "The name of the temporary VM used to create the custom image."
  type        = string
  default     = "temp-image-builder-vm"
}

variable "custom_image_name" {
  description = "The name for the custom Managed Image to be created."
  type        = string
  default     = "my-first-custom-ubuntu-image"
}

variable "admin_username" {
  description = "The administrator username for the temporary Linux VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "The file path to your SSH public key (e.g., ./id_rsa.pub)."
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
    Environment = "ImageBuilding"
    Project     = "CustomImage"
  }
}

# 2. Azure Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3. Azure Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


# 5. Network Security Group (NSG) for the temporary VM
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-nsg"
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
}

# 6. Associate NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 7. Network Interface for the temporary VM
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    primary                       = true
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# 8. Explicitly associate the Network Interface with the NSG
# This resource is needed because direct association within network_interface block is deprecated or problematic.
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 9. Cloud-init script for Linux VM generalization
# This script runs on first boot to generalize the VM.
# Important: The VM will become unusable after deprovisioning.
locals {
  cloud_init_script = <<-EOF
    #!/bin/bash
    sudo waagent -deprovision+user -force
    # Note: waagent will shut down the VM after deprovisioning.
    # Terraform will then proceed to capture the image.
  EOF
}

# 10. Temporary Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" # Very small, cost-effective VM size
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]
  disable_password_authentication = true # Use SSH keys

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

  # Use cloud_init to generalize the VM on first boot
  custom_data = base64encode(local.cloud_init_script)

  # Terraform waits for the VM to be provisioned before proceeding
  # The VM will then deprovision itself via cloud-init and shut down
}

# 11. Capture the Custom Managed Image
# This resource depends on the VM being created AND deprovisioned/shut down by cloud-init.
resource "azurerm_image" "custom_image" {
  name                = var.custom_image_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_disk {
    os_type         = "Linux"
    managed_disk_id = azurerm_linux_virtual_machine.vm.os_disk[0].id
    storage_type    = "Standard_LRS"
    os_state        = "Generalized"
  }


  # Ensure the VM is created and then automatically generalized/shut down by cloud-init
  # before attempting to capture the image.
  # Terraform handles the implicit dependency of azurerm_image on azurerm_linux_virtual_machine.vm
  # via managed_disk_id referencing vm.os_disk_id.
}

# 12. Delete the temporary VM after image capture
# This step ensures cleanup of the VM, which cannot be reused after generalization.
# Use a local-exec provisioner to delete the VM resource via Azure CLI.
# This ensures the VM is gone but its managed disk is retained for the image.
resource "null_resource" "delete_vm_after_capture" {
  triggers = {
    custom_image_id = azurerm_image.custom_image.id # Trigger after image is captured
  }

  provisioner "local-exec" {
    command = "az vm delete --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_linux_virtual_machine.vm.name} --yes --no-wait"
    # --no-wait makes the command non-blocking for faster Terraform execution.
    # --yes confirms the deletion.
  }

  # This ensures the null_resource runs AFTER the VM is created and the image is captured
  depends_on = [
    azurerm_image.custom_image,
    azurerm_linux_virtual_machine.vm # Explicit dependency to ensure VM is there before attempting delete
  ]
}


output "custom_image_id" {
  description = "The ID of the created custom Managed Image."
  value       = azurerm_image.custom_image.id
}

output "custom_image_name" {
  description = "The name of the created custom Managed Image."
  value       = azurerm_image.custom_image.name
}


output "next_steps" {
  description = "Use this image ID to create new VMs. Example: `azurerm_linux_virtual_machine` -> `source_image_id = azurerm_image.custom_image.id`"
  value       = "To use your custom image, set `source_image_id = ${azurerm_image.custom_image.id}` in a new `azurerm_linux_virtual_machine` resource."
}

