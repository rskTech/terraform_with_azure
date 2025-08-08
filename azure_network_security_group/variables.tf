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
