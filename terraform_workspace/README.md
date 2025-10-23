# 🧭 Terraform Workspaces — Managing Multiple Environments

Terraform **workspaces** are a lightweight mechanism built into Terraform to manage multiple distinct instances of a given set of configuration files (for example: `dev`, `staging`, `prod`) while reusing the same configuration. This guide explains workspaces step-by-step, how to manage multiple environments, and how to use workspace-specific variables safely.

---

## 1) What is a Terraform workspace?

A **workspace** is a named context that associates a Terraform state file with that name. The default workspace is called `default`. When you switch workspaces, Terraform reads/writes a different state for each workspace — you can think of it as a lightweight way to maintain multiple independent deployments from the *same* configuration.

**Key point:** Workspaces isolate *state*, not configuration. The `.tf` files are the same; state and any outputs are separate.

---

## 2) When to use workspaces

Use workspaces when:
- You want **multiple instances** of identical infrastructure (e.g., multiple tenant sandboxes).
- You need a **simple** way to separate environments (dev, qa, stage) for small projects.

Avoid workspaces for:
- Large production environments with different architectures. For complex infra, prefer separate directories/repos per environment or modules + remote backends keyed per environment.

---

## 3) Basic workspace commands (step-by-step)

> Run these in your Terraform project directory (where you run `terraform init`).

### Initialize a project
```bash
terraform init
```
List workspaces
```
terraform workspace list
```

Expected output (example):
```
default
* dev
  staging
```

* marks the current workspace.

Create a new workspace
```
terraform workspace new dev
```

Output:
```
Created and switched to workspace "dev"!
```
Switch workspace
```
terraform workspace select staging
```

Output:
```
Switched to workspace "staging".
```
Show current workspace
```
terraform workspace show
```

Output example:
```
dev
```
## Example workflow (create a resource per workspace)

main.tf
```
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${terraform.workspace}"
  location = var.location
}

```
variables.tf
```
variable "location" {
  type    = string
  default = "East US"
}

```
Steps
```
terraform init

terraform workspace new dev

terraform apply -auto-approve
```
Creates resource group rg-dev
```
terraform workspace new staging

terraform apply -auto-approve
```
Creates resource group rg-staging

Each workspace created its own RG because terraform.workspace was used in the resource name.

## Workspace-specific variables

Terraform has several ways to provide variables; workspace-specific variables manage different values per workspace.

### terraform.tfvars per workspace (not built-in)

Terraform doesn't have built-in tfvars per workspace; you must adopt conventions:

Convention 1: named tfvars files
```
dev.tfvars

staging.tfvars

prod.tfvars
```
Use at plan/apply:
```
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

Pros: Explicit, simple.
Cons: Manual selection; easy to forget.
## Example end-to-end (commands)
```
# init once
terraform init

# create/select dev workspace and apply
terraform workspace new dev
terraform workspace show      # dev
terraform apply -auto-approve

# create/select staging workspace and apply
terraform workspace new staging
terraform workspace select staging
terraform apply -auto-approve

# list workspaces
terraform workspace list

# check state resources in current workspace
terraform state list
```
## Exercises 

- Create a simple config that provisions an Azure Resource Group named rg-${terraform.workspace}.

-- Create dev and staging workspaces and apply; validate two resource groups were created.

-- Implement a locals mapping to set location and vm_size per workspace (dev/staging/prod) and create a resource (e.g., storage account) that uses those values.
