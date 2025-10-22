## Terraform Modules with Azure
### 📘 Introduction

Terraform modules are the building blocks of reusable, maintainable, and scalable infrastructure-as-code.
A module is simply a collection of Terraform configuration files (.tf files) in a directory.

Modules allow you to:

Encapsulate and reuse common configurations.

Organize your code better.

Parameterize infrastructure with input variables.

Output useful information to other configurations.

### 🧩 Why Use Modules?

Without modules, your Terraform files can become large and repetitive.
For example, if you need multiple resource groups, VNets, or storage accounts — modules let you reuse code with different inputs.

#### ✅ Benefits:

Reusability

Better organization

Collaboration (multiple team members work on different modules)

Easier maintenance

#### 🗂️ Module Folder Structure
```
terraform-azure/
│
├── main.tf                # Root module entry point
├── variables.tf           # Input variables for the root module
├── outputs.tf             # Outputs from the root module
├── provider.tf            # Azure provider configuration
│
├── modules/
│   ├── resource-group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── storage-account/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│
└── terraform.tfvars       # Default values for variables

```

## ⚙️ Step 1: Configure the Azure Provider

provider.tf
```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```
## 🧱 Step 2: Create a Module (Example: Resource Group)

modules/resource-group/main.tf

```
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

```
modules/resource-group/variables.tf
```
variable "rg_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}
```

modules/resource-group/outputs.tf
```
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
```
## 📦 Step 3: Use the Module in Root Configuration

main.tf
```
module "rg_student" {
  source   = "./modules/resource-group"
  rg_name  = "student-rg-01"
  location = "East US"
}

```
You can reuse this same module for multiple students:
```
module "rg_student1" {
  source   = "./modules/resource-group"
  rg_name  = "student1-rg"
  location = "East US"
}

module "rg_student2" {
  source   = "./modules/resource-group"
  rg_name  = "student2-rg"
  location = "East US"
}
```
## 🪣 Step 4: Example of a Second Module — Storage Account

modules/storage-account/main.tf
```
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

modules/storage-account/variables.tf
```
variable "storage_account_name" {
  description = "Storage account name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Location"
  type        = string
}

```
modules/storage-account/outputs.tf
```
output "storage_account_id" {
  value = azurerm_storage_account.sa.id
}

```
Now, use it in your main Terraform file:
```
module "storage_student" {
  source                = "./modules/storage-account"
  storage_account_name  = "studenta123sa"
  resource_group_name   = module.rg_student.resource_group_name
  location              = "East US"
}
```
## 🧪 Step 5: Run the Terraform Commands
```
# Initialize modules and providers
terraform init

# Validate configuration
terraform validate

# See the execution plan
terraform plan

# Apply the configuration
terraform apply -auto-approve

# Destroy when done
terraform destroy -auto-approve
```

## ✅ Expected Output:
Terraform will create:

A resource group named student-rg-01

A storage account inside that resource group

🔍 Step 6: Using Remote Modules (Optional)

You can host your modules on:

GitHub:
```
module "rg" {
  source   = "github.com/rskTech/terraform-azure-modules//resource-group"
  rg_name  = "demo-rg"
  location = "West Europe"
}
```

## 🧠 Key Concepts Recap
| Concept             | Description                            | Example                        |
| ------------------- | -------------------------------------- | ------------------------------ |
| **Root Module**     | Main Terraform configuration directory | `main.tf`                      |
| **Child Module**    | Reusable component used by root module | `modules/resource-group`       |
| **Input Variables** | Parameters passed to a module          | `var.rg_name`                  |
| **Outputs**         | Values returned by a module            | `output "resource_group_name"` |
| **Source**          | Path to module code (local or remote)  | `"./modules/storage-account"`  |


## 🧩 Best Practices

Keep modules small and focused.

Use input validation for variables.

Version-control your modules (use Git tags).

Avoid hardcoding sensitive data.

Document each module with usage examples.

## 🚀 End-to-End Example

This creates a resource group, storage account, and container using modules.

main.tf

```
module "rg" {
  source   = "./modules/resource-group"
  rg_name  = "final-demo-rg"
  location = "East US"
}

module "sa" {
  source                = "./modules/storage-account"
  storage_account_name  = "finaldemostorage123"
  resource_group_name   = module.rg.resource_group_name
  location              = "East US"
}
```

Run:
```
terraform init
terraform apply -auto-approve
```

Output:
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```
Outputs:
```
resource_group_name = "final-demo-rg"
storage_account_id  = "/subscriptions/.../storageAccounts/finaldemostorage123"
```
## 🧾 Summary

Terraform modules make infrastructure reusable and manageable.

You can build modular, parameterized templates for Azure resources.

Each student can deploy their own isolated environment using the same modules.
