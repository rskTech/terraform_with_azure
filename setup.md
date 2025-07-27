# Terraform Setup on Linux VM (EC2) for Azure Infrastructure

This guide will help you set up Terraform on a Linux VM (Ubuntu or Amazon Linux), configure Azure credentials, and use Terraform to create resources in Azure.

---

## ✅ Prerequisites

* A running **Linux VM (EC2 or any cloud)** with internet access
* An **Azure subscription**
* Terraform-compatible **Azure Service Principal**

---

## 🔐 1. Connect to Your Linux VM

SSH into your VM:

```bash
ssh -i your-key.pem ec2-user@<your-ec2-public-ip>
```

> Replace `ec2-user` with `ubuntu` for Ubuntu machines.

---

## 🧰 2. Install Terraform

### On Ubuntu:

```bash
sudo apt-get update -y
sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install terraform -y

terraform -version
```

### On Amazon Linux:

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y

terraform -version
```

---

## ☁️ 3. Install Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az version
```

---

## 🔑 4. Create and Configure Azure Credentials

### Option A: Use Azure Service Principal (Recommended)

1. On your local system or Azure Cloud Shell, run:

```bash
az login
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" \
  --scopes="/subscriptions/<your-subscription-id>"
```

This will output:

```json
{
  "appId": "xxxxxx",
  "displayName": "terraform-sp",
  "password": "xxxxxx",
  "tenant": "xxxxxx"
}
```

2. On your Linux VM, export these credentials:

```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
export ARM_TENANT_ID="<tenant>"
```

> To persist across reboots, add them to `~/.bashrc`:

```bash
echo 'export ARM_CLIENT_ID="<appId>"' >> ~/.bashrc
echo 'export ARM_CLIENT_SECRET="<password>"' >> ~/.bashrc
echo 'export ARM_SUBSCRIPTION_ID="<subscriptionId>"' >> ~/.bashrc
echo 'export ARM_TENANT_ID="<tenant>"' >> ~/.bashrc
source ~/.bashrc
```

---

## 📁 5. Clone Terraform Project and Deploy Azure Resources

```bash
git clone https://github.com/rskTech/terraform_with_azure.git
cd terraform_with_azure
```

Then run:

```bash
terraform init
terraform plan
terraform apply
```

You can now provision Azure infrastructure securely from your Linux-based Terraform Dev VM. 🎉
