# 🔐 Azure Authentication for Terraform

This guide explains how to authenticate Terraform with your Azure subscription using a **Service Principal**.

---

## ✅ Prerequisite: Azure Free Subscription

If you don't already have an Azure account:

1. Go to [https://azure.microsoft.com/en-in/free](https://azure.microsoft.com/en-in/free)
2. Sign in with a Microsoft account.
3. Verify your phone number and credit/debit card (₹2 refundable).
4. You’ll get ₹14,500 (\~\$200) free credit for 30 days.

---

## 🔧 Step-by-Step: Create a Terraform-Compatible Azure Service Principal

### 1. Login to Azure

```bash
az login
```

### 2. Set Active Subscription (if multiple exist)

```bash
az account list --output table
az account set --subscription "<Your Subscription Name or ID>"
```

### 3. Create the Service Principal

```bash
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<SUBSCRIPTION_ID>" \
  --sdk-auth
```

> Replace `<SUBSCRIPTION_ID>` with your actual subscription ID.

### Example Output:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

✅ Save this output securely as `azure-credentials.json`.

---

## 🔧 Configure Terraform with Azure Credentials

You can authenticate Terraform in one of two ways:

### **Option 1: Using Environment Variables**

```bash
export ARM_CLIENT_ID="<clientId>"
export ARM_CLIENT_SECRET="<clientSecret>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
export ARM_TENANT_ID="<tenantId>"
```

### **Option 2: Using Provider Block in Terraform**

Add this to your `main.tf`:

```hcl
provider "azurerm" {
  features {}

  client_id       = "<clientId>"
  client_secret   = "<clientSecret>"
  subscription_id = "<subscriptionId>"
  tenant_id       = "<tenantId>"
}
```
You're now ready to use Terraform to provision Azure resources securely!
