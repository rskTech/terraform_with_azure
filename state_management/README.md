# Terraform State Management
## 📘 Introduction

Terraform state is a critical part of how Terraform works.
It’s the single source of truth that keeps track of all the infrastructure resources created, updated, or destroyed by Terraform.

When you run terraform apply, Terraform:

Reads your configuration files (.tf)

Checks the current state of resources (from the state file)

Figures out what needs to change

Applies those changes and updates the state file

Without state, Terraform wouldn’t know what already exists and might try to recreate everything each time.

## 🧠 Why Terraform State Is Important

Terraform state enables:

Mapping real-world resources to Terraform configuration.

Performance optimization (no need to query cloud provider every time).

Tracking dependencies between resources.

Collaboration via remote state for teams.

## 📂 Where Is the State Stored?

By default, Terraform stores state locally in a file called:
```
terraform.tfstate

```
This file contains:

Resource metadata (IDs, names, configurations)

Dependencies between resources

Sensitive information (like passwords, secrets, etc.)

⚠️ Important: Never manually edit or commit terraform.tfstate to GitHub — it may contain sensitive data.

## 🏠 Local State

By default, Terraform saves the state file locally in your project directory.

### Advantages:

Simple setup

No additional configuration

### Disadvantages:

Not suitable for teams (no shared state)

Higher risk of corruption or accidental deletion

No locking (two users may apply changes simultaneously)

Example:
```
terraform init
terraform apply
```

This creates a local terraform.tfstate file.

## 🌐 Remote State

Remote state allows multiple users to share a single state securely using backends like:

- Azure Blob Storage

- AWS S3

- Google Cloud Storage

- Terraform Cloud

- Consul

### Advantages:

Enables team collaboration

Supports state locking and versioning

Safer and more reliable than local

## 🪣 Example: Remote State in Azure Blob Storage

backend.tf
```
terraform {
  backend "azurerm" {
    resource_group_name   = "terraform-storage-rg"
    storage_account_name  = "tfstatestorageacct"
    container_name        = "tfstate"
    key                   = "prod.terraform.tfstate"
  }
}
```

Steps:

Create a storage account and container in Azure.

Add the above backend configuration.

Run:
```
terraform init
```

Terraform will automatically configure and migrate your state to Azure.

✅ Expected Output:
```
Terraform has been successfully initialized!
Backend has been configured to use AzureRM
```
## 🔒 State Locking and Consistency

When multiple people or automation pipelines work with the same Terraform project, state locking prevents race conditions — situations where two people try to update infrastructure simultaneously.

Locking ensures only one terraform apply or terraform plan runs at a time.

Consistency guarantees that your infrastructure changes are based on the latest state.

Supported Backends with Locking:

- Azure Blob Storage

- AWS S3 with DynamoDB

- Terraform Cloud

## 🧩 Example of State Locking in Azure Backend

When you use the AzureRM backend:

Terraform automatically locks the state file when an operation begins.

It releases the lock after completion or failure.

You may see:
```
Acquiring state lock. This may take a few moments...
```

and then:

Releasing state lock. This may take a few moments...


This ensures only one user updates the state at a time.

🧾 Common Terraform State Commands
| Command                           | Description                                           |
| --------------------------------- | ----------------------------------------------------- |
| `terraform state list`            | Lists all resources in the current state file         |
| `terraform state show <resource>` | Displays details of a specific resource               |
| `terraform state rm <resource>`   | Removes a resource from state (won’t delete in Azure) |
| `terraform refresh`               | Syncs state file with actual cloud resources          |
| `terraform import`                | Adds existing cloud resources into Terraform state    |

## 🧪 Practical Example
Step 1: Create Local State
```
terraform init
terraform apply -auto-approve
```

This creates a local terraform.tfstate.

Step 2: Migrate to Remote State
```
terraform init -migrate-state
```

Expected output:
```
Successfully migrated state to backend "azurerm"!
```
Step 3: Verify

Run:
```
terraform state list
```

You’ll see resources listed from the Azure state backend.

## 🧠 Best Practices

✅ DO:

Use remote backend for team collaboration.

Enable state locking.

Backup state files regularly.

Use separate state files per environment (e.g., dev, stage, prod).

🚫 DON’T:

Commit terraform.tfstate or .terraform/ folder to GitHub.

Manually edit the state file.

Share your state file insecurely.

🧩 Example: Team Setup for Students Using Remote State

If each student is deploying their own environment in your Azure account:

Create separate containers or keys in Azure Blob for each student:
```
key = "student1.tfstate"
key = "student2.tfstate"
```

Each student runs Terraform independently but shares the same Azure backend.

## Summary

| Concept          | Description                                                       |
| ---------------- | ----------------------------------------------------------------- |
| **State**        | Tracks real-world resources managed by Terraform                  |
| **Local State**  | Stored on disk, suitable for single user                          |
| **Remote State** | Stored in Azure/AWS/GCP; supports team use                        |
| **Locking**      | Prevents multiple simultaneous changes                            |
| **Consistency**  | Ensures Terraform always works on the latest known infrastructure |
