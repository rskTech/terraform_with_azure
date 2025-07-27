🚀 Terraform Setup on Linux VM (EC2) for Azure Infrastructure Provisioning
This document provides a step-by-step guide to install Terraform on a Linux VM (Ubuntu/Amazon Linux), configure Azure credentials, and prepare the system to provision Azure services using Terraform.

🧰 Prerequisites
A running Linux VM (Ubuntu or Amazon Linux 2) with SSH access.

An Azure account and Service Principal created.

Basic understanding of Terraform.

🖥️ 1. Connect to Linux VM
SSH into your EC2 or other Linux VM:

ssh -i your-key.pem ec2-user@<your-ec2-ip>
For Ubuntu, replace ec2-user with ubuntu.

🛠️ 2. Install Terraform
On Ubuntu:
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
On Amazon Linux:
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y

terraform -version
☁️ 3. Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az version
🔐 4. Authenticate with Azure
Option 1: Use a Service Principal (recommended for automation)
a. On your local machine (or Azure Cloud Shell), create a Service Principal:
az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" \
  --scopes="/subscriptions/<your-subscription-id>"
This command outputs:

{
  "appId": "xxxxx-xxxx-xxxx",
  "displayName": "terraform-sp",
  "password": "xxxxx-xxxxx",
  "tenant": "xxxxx-xxxx-xxxx"
}
b. On the Linux VM, export these as environment variables:
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
export ARM_TENANT_ID="<tenant>"
Add them to ~/.bashrc for persistence:

echo 'export ARM_CLIENT_ID="..."' >> ~/.bashrc
echo 'export ARM_CLIENT_SECRET="..."' >> ~/.bashrc
echo 'export ARM_SUBSCRIPTION_ID="..."' >> ~/.bashrc
echo 'export ARM_TENANT_ID="..."' >> ~/.bashrc
source ~/.bashrc
📂 5. Clone Terraform Project and Initialize
git clone https://github.com/<your-username>/azure-terraform-infra.git
cd azure-terraform-infra
Initialize the Terraform backend and provider:

terraform init
terraform plan
terraform apply
📌 Notes
Avoid committing terraform.tfvars or credentials to Git.

You can also use Terraform Cloud for state storage and remote execution.

✅ Example Terraform Provider Block
provider "azurerm" {
  features {}
}
Terraform automatically picks up the Azure environment variables (ARM_*) for authentication.
