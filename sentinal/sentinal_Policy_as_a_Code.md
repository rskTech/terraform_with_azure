## 🛡️ Introduction to Sentinel for Policy Management

Sentinel is HashiCorp’s Policy as Code (PaC) framework used to enforce fine-grained, logic-based policies across the Terraform ecosystem.
It allows organizations to define governance rules that control what infrastructure changes can be made, ensuring security, compliance, and operational consistency.

### 📘 1. Overview of Policy as Code
What is Policy as Code?

Policy as Code (PaC) is the practice of writing and managing organizational rules and compliance policies in code form — similar to how you write application or infrastructure code.

Instead of manual approvals or spreadsheets, PaC automates:

Security validation (e.g., ensure encryption enabled)

Compliance enforcement (e.g., tagging standards)

Cost governance (e.g., restrict large VM sizes)

Sentinel allows these rules to be version-controlled, tested, and integrated directly into CI/CD pipelines.

### Sentinel Policy Lifecycle
| Stage       | Description                                                 |
| ----------- | ----------------------------------------------------------- |
| **Define**  | Write Sentinel policy rules as `.sentinel` files            |
| **Test**    | Validate policies with test cases before enforcement        |
| **Enforce** | Attach policies to workspaces in Terraform Cloud/Enterprise |
| **Monitor** | Track compliance and violations in dashboards               |
```
# restrict_vm_size.sentinel
# Ensure no large instance sizes are used in Terraform plans

import "tfplan"

main = rule {
    all tfplan.resources.aws_instance as _, instances {
        all instances as _, instance {
            instance.applied.instance_type in ["t2.micro", "t3.small", "t3.medium"]
        }
    }
}

```
🧠 Explanation:

The policy loads Terraform plan data (tfplan import).

It loops through all EC2 instances and checks their type.

Any disallowed instance type will cause the policy to fail.

### Policy Enforcement Levels
| Enforcement Mode   | Behavior                               |
| ------------------ | -------------------------------------- |
| **Advisory**       | Warns but allows the run to continue   |
| **Soft Mandatory** | Fails the run, but admins can override |
| **Hard Mandatory** | Fails the run, no override allowed     |

## ⚙️ 2. How Policies Affect Provider Permissions and Resource Management

Sentinel can restrict or allow Terraform provider actions at a fine-grained level.
This ensures users deploy only approved resources or configurations.

### A. Controlling Provider Permissions

You can use Sentinel to limit which Terraform provider or specific resource types can be used.

Example: Restrict Provider Usage
```
# disallow_unapproved_provider.sentinel
import "tfconfig"

main = rule {
    all tfconfig.providers as name, _ {
        name in ["hashicorp/azurerm", "hashicorp/aws"]
    }
}

```
✅ Explanation:

Only the azurerm and aws providers are allowed.

If someone tries to use google or kubernetes, the plan fails.

### B. Managing Resource Permissions

Sentinel can also control resource creation, such as enforcing:

Storage accounts must have encryption.

VMs must belong to specific resource groups.

Example: Enforce Resource Group Naming Convention (Azure)
```
# enforce_rg_naming.sentinel
import "tfplan"

main = rule {
    all tfplan.resources.azurerm_resource_group as _, rgs {
        all rgs as _, rg {
            startswith(rg.applied.name, "student-")
        }
    }
}
```

💡 Explanation:

Ensures all resource groups created in Azure start with student-.

Perfect for training environments where each student gets isolated resources.

## 🧱 3. Best Implementation of Provider-Focused Policies

Implementing Sentinel policies effectively involves integrating them into your Terraform workflow in a structured, scalable way.

### Step 1: Organize Policy Repositories

Maintain a centralized policy repository such as:
```
/sentinel-policies/
│
├── restrict_vm_size.sentinel
├── enforce_rg_naming.sentinel
├── disallow_unapproved_provider.sentinel
└── tests/
    ├── restrict_vm_size_test.json
    └── enforce_rg_naming_test.json

```
This helps reuse and version policies across multiple teams and projects.

### Step 2: Integrate with Terraform Cloud or Enterprise

In Terraform Cloud/Enterprise, Sentinel runs automatically during:

Plan phase

Apply phase

You can assign policies to:

Organizations

Workspaces

For example:

Allow only azurerm provider for student workspaces.

Enforce tagging or cost limits for production workspaces.

### Step 3: Use Mock Data for Testing

Before enforcing, always test policies using mock data.
```
sentinel test restrict_vm_size.sentinel


✅ Sample Test File (restrict_vm_size_test.json)

{
  "mock": {
    "tfplan": {
      "resources": {
        "aws_instance": {
          "web": {
            "applied": { "instance_type": "t2.micro" }
          }
        }
      }
    }
  },
  "test": {
    "main": true
  }
}
```
### Step 4: Policy Versioning and Review

Store policies in Git for code reviews and traceability.

Enforce semantic versioning (v1.0.0, v1.1.0, etc.)

Use CI/CD to validate policies automatically.

### Step 5: Align with Organizational Roles

Admins define and maintain global policies.

Developers focus on resource implementation.

Security Teams ensure policies align with compliance frameworks (ISO, CIS, etc.).

## 🚀 Example: Complete Sentinel Policy for Azure Training Lab

Here’s a combined example ensuring each student:

Uses only allowed providers.

Creates resource groups with proper names.

Does not exceed VM size limits.
```
import "tfconfig"
import "tfplan"

# Allow only azurerm provider
allowed_providers = ["hashicorp/azurerm"]

provider_check = rule {
    all tfconfig.providers as name, _ {
        name in allowed_providers
    }
}

# Ensure RG name starts with 'student-'
rg_check = rule {
    all tfplan.resources.azurerm_resource_group as _, rgs {
        all rgs as _, rg {
            startswith(rg.applied.name, "student-")
        }
    }
}

# Allow only small VM sizes
vm_check = rule {
    all tfplan.resources.azurerm_linux_virtual_machine as _, vms {
        all vms as _, vm {
            vm.applied.size in ["Standard_B1s", "Standard_B2s"]
        }
    }
}

main = rule { provider_check and rg_check and vm_check }
```
## ✅ Key Takeaways
| Concept                  | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| **Sentinel**             | HashiCorp’s Policy as Code framework for Terraform Cloud/Enterprise            |
| **Policy as Code**       | Automates compliance and governance using logic-based rules                    |
| **Provider Permissions** | Controls which providers and resources can be used                             |
| **Policy Enforcement**   | Defines whether policy failures block or allow runs                            |
| **Best Practices**       | Separate policies, version control, test with mock data, and enforce centrally |

## 🧠 Summary

Sentinel ensures your Terraform usage is secure, consistent, and compliant across all environments.
By defining provider-focused policies, you can:

Prevent misconfigurations.

Limit resource creation scope.

Streamline governance for multi-user or multi-student setups.
