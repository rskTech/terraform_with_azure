## 🧪 Testing Custom Terraform Providers (Step-by-Step Guide)

This guide demonstrates how to test and use your own Terraform provider in a real working setup.

We’ll build a mini “Example” provider that:

Uses a fake API client (no external calls)

Implements one resource (example_user)

Implements one data source (example_user_info)

Shows how to test & use it with Terraform

## 🧩 Folder Structure
```
example-provider/
│
├── main.go
├── provider.go
├── resource_user.go
├── data_source_user.go
├── go.mod
├── go.sum
└── examples/
    └── main.tf
```
## ⚙️ 1. Define the Provider

File: provider.go
```
package example

import (
	"context"
	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func Provider() *schema.Provider {
	return &schema.Provider{
		Schema: map[string]*schema.Schema{
			"api_token": {
				Type:        schema.TypeString,
				Required:    true,
				Description: "Fake API token (not used here)",
			},
		},

		ResourcesMap: map[string]*schema.Resource{
			"example_user": resourceUser(),
		},

		DataSourcesMap: map[string]*schema.Resource{
			"example_user_info": dataSourceUser(),
		},

		ConfigureContextFunc: providerConfigure,
	}
}

func providerConfigure(ctx context.Context, d *schema.ResourceData) (interface{}, diag.Diagnostics) {
	client := NewFakeClient()
	return client, nil
}
```
## 👨‍💻 2. Create a Fake API Client

File: client.go
```
package example

type FakeClient struct {
	users map[string]string
}

func NewFakeClient() *FakeClient {
	return &FakeClient{users: make(map[string]string)}
}

func (c *FakeClient) CreateUser(name, email string) error {
	c.users[email] = name
	return nil
}

func (c *FakeClient) GetUser(email string) (string, bool) {
	name, ok := c.users[email]
	return name, ok
}

func (c *FakeClient) UpdateUser(email, newName string) {
	c.users[email] = newName
}

func (c *FakeClient) DeleteUser(email string) {
	delete(c.users, email)
}
```
## 👤 3. Implement Resource — example_user

File: resource_user.go
```
package example

import (
	"context"
	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func resourceUser() *schema.Resource {
	return &schema.Resource{
		CreateContext: resourceUserCreate,
		ReadContext:   resourceUserRead,
		UpdateContext: resourceUserUpdate,
		DeleteContext: resourceUserDelete,

		Schema: map[string]*schema.Schema{
			"name": {
				Type:     schema.TypeString,
				Required: true,
			},
			"email": {
				Type:     schema.TypeString,
				Required: true,
			},
		},
	}
}

func resourceUserCreate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
	client := m.(*FakeClient)
	name := d.Get("name").(string)
	email := d.Get("email").(string)

	client.CreateUser(name, email)
	d.SetId(email)
	return resourceUserRead(ctx, d, m)
}

func resourceUserRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
	client := m.(*FakeClient)
	email := d.Id()

	name, ok := client.GetUser(email)
	if !ok {
		d.SetId("") // resource deleted
		return nil
	}
	d.Set("name", name)
	d.Set("email", email)
	return nil
}

func resourceUserUpdate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
	client := m.(*FakeClient)
	if d.HasChange("name") {
		email := d.Id()
		newName := d.Get("name").(string)
		client.UpdateUser(email, newName)
	}
	return resourceUserRead(ctx, d, m)
}

func resourceUserDelete(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
	client := m.(*FakeClient)
	client.DeleteUser(d.Id())
	d.SetId("")
	return nil
}
```
## 📚 4. Implement Data Source — example_user_info

File: data_source_user.go
```
package example

import (
	"context"
	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

func dataSourceUser() *schema.Resource {
	return &schema.Resource{
		ReadContext: dataSourceUserRead,

		Schema: map[string]*schema.Schema{
			"email": {
				Type:     schema.TypeString,
				Required: true,
			},
			"name": {
				Type:     schema.TypeString,
				Computed: true,
			},
		},
	}
}

func dataSourceUserRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
	client := m.(*FakeClient)
	email := d.Get("email").(string)
	name, ok := client.GetUser(email)
	if !ok {
		return diag.Errorf("User with email %s not found", email)
	}
	d.SetId(email)
	d.Set("name", name)
	return nil
}
```
## 🚀 5. Provider Entrypoint

File: main.go
```
package main

import (
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
	"example"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: example.Provider,
	})
}
```
## 🔨 6. Build and Install the Provider
```
go mod init example
go mod tidy

# Build provider binary
go build -o terraform-provider-example
```

Move it to your local Terraform plugins folder:
```
mkdir -p ~/.terraform.d/plugins/local/example/1.0.0/linux_amd64
mv terraform-provider-example ~/.terraform.d/plugins/local/example/1.0.0/linux_amd64/
```
## 🧠 7. Example Terraform Configuration

File: examples/main.tf
```
terraform {
  required_providers {
    example = {
      source  = "local/example"
      version = "1.0.0"
    }
  }
}

provider "example" {
  api_token = "dummy-token"
}

resource "example_user" "student1" {
  name  = "Rajendra"
  email = "rajendra@example.com"
}

data "example_user_info" "check_user" {
  email = example_user.student1.email
}

output "user_name" {
  value = data.example_user_info.check_user.name
}
```
## ▶️ 8. Run and Test It
```
cd examples
terraform init
terraform apply -auto-approve
```

✅ Expected Output:
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
Outputs:
```
user_name = "Rajendra"
```
## 🧩 9. Testing Custom Provider (Go Unit Test)

You can create a quick test file:

File: provider_test.go
```
package example

import "testing"

func TestFakeClient(t *testing.T) {
	client := NewFakeClient()
	client.CreateUser("Ira", "ira@example.com")

	name, found := client.GetUser("ira@example.com")
	if !found || name != "Ira" {
		t.Fatalf("expected user Ira, got %s", name)
	}
}

```
Run:
```
go test ./... -v

```
✅ Output:
```
=== RUN   TestFakeClient
--- PASS: TestFakeClient (0.00s)
PASS
```
