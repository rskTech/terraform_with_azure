## 🧩 Writing Custom Terraform Providers

Terraform providers act as the bridge between Terraform and external APIs (like AWS, Azure, GitHub, or your own systems).
If a service or platform doesn’t have an existing provider, you can create your own custom provider using Go.

## 🚀 What Is a Terraform Provider?

A provider is a Terraform plugin that enables Terraform to interact with APIs of external systems — creating, reading, updating, and deleting (CRUD) resources.

For example:

azurerm → manages Azure resources

aws → manages AWS resources

kubernetes → manages Kubernetes clusters

Custom Provider → could manage your internal API or tool

###🧱 Provider Structure Overview

A Terraform provider plugin typically has:
```
terraform-provider-example/
├── main.go               # Entry point
├── provider.go           # Provider schema and configuration
├── resource_example.go   # Defines resource schema and CRUD logic
├── data_source_example.go# Optional: for reading external data
├── go.mod                # Go module dependencies
└── docs/                 # Documentation (optional)
```
