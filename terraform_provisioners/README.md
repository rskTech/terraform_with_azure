## Terraform Provisioners

Provisioners in Terraform are used to execute scripts or commands on a local or remote machine after a resource is created or destroyed.
They act as a “last mile” configuration mechanism — useful when certain setup tasks cannot be done using Terraform providers directly.

### 🔹 Understanding Provisioners

Provisioners are defined inside a resource block and are typically used to:

Run initialization scripts

Configure applications

Copy files to VMs

Execute configuration management tools (like Ansible, Chef, Puppet)

However, provisioners should be used sparingly — only when no other Terraform-native method exists.

### ⚙️ Types of Provisioners
#### 1. Local-Exec Provisioner

The local-exec provisioner runs commands on the machine running Terraform, not on the remote resource.

Example:
```
resource "azurerm_virtual_machine" "example" {
  name                  = "myVM"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_B1s"

  # ... other configurations ...

  provisioner "local-exec" {
    command = "echo VM ${self.name} has been created successfully >> vm_log.txt"
  }
}
```
Explanation:

The local-exec command runs on your local system.

${self.name} refers to the resource’s attributes.

Useful for:

Triggering notifications

Running local validation

Updating external systems or CI/CD pipelines

#### 2. Remote-Exec Provisioner

The remote-exec provisioner runs commands on the remote machine (e.g., a VM) after creation.

Example:
```
resource "azurerm_linux_virtual_machine" "webserver" {
  name                = "webserver"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [azurerm_network_interface.example.id]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install nginx -y",
      "sudo systemctl start nginx"
    ]

    connection {
      type        = "ssh"
      user        = "azureuser"
      password    = "P@ssword1234!"
      host        = self.public_ip_address
    }
  }
}
```
Explanation:

The commands inside inline run on the VM after it’s provisioned.

The connection block defines how Terraform connects to the machine (SSH, WinRM, etc.).

Useful for:

Bootstrapping a VM

Installing software (like web servers)

Configuring application dependencies

#### 3. File Provisioner

The file provisioner is used to copy files or directories from the local machine to a remote resource.

Example:
```
resource "azurerm_linux_virtual_machine" "appserver" {
  name                = "appserver"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [azurerm_network_interface.example.id]

  # Copy a local script to remote VM
  provisioner "file" {
    source      = "scripts/setup.sh"
    destination = "/tmp/setup.sh"

    connection {
      type        = "ssh"
      user        = "azureuser"
      password    = "P@ssword1234!"
      host        = self.public_ip_address
    }
  }

  # Execute the copied script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "azureuser"
      password    = "P@ssword1234!"
      host        = self.public_ip_address
    }
  }
}
```
Explanation:

The file provisioner copies scripts/setup.sh to the VM.

After copying, the script is executed using a remote-exec provisioner.

Commonly used for:

Uploading configuration scripts

Copying SSL certificates

Transferring config files

### ⚠️ Best Practices

✅ Prefer Terraform resources or cloud-init for setup instead of provisioners.
✅ Use provisioners only when absolutely necessary (e.g., for non-API accessible tasks).
✅ Always handle failures gracefully using:
```
provisioner "remote-exec" {
  on_failure = continue
}
```

✅ Store secrets (like passwords or SSH keys) securely using environment variables or secret managers.
✅ For production, use Remote State + Automation Pipelines (not manual Terraform apply).

🧩 Example Project Structure
```
terraform-azure-provisioners/
├── main.tf
├── variables.tf
├── scripts/
│   └── setup.sh
└── outputs.tf
```
✅ Example Output
```
terraform init
terraform apply -auto-approve
```

Output:
```
azurerm_linux_virtual_machine.appserver: Creation complete
Running provisioner: file...
Running provisioner: remote-exec...
VM setup complete with Nginx installed!
```
