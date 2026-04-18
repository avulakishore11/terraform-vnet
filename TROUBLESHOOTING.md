# Troubleshooting Guide — terraform-vnet

---

## 1. Git Merge Conflict on `main.tf`

**Error:**
```
error: Your local changes to the following files would be overwritten by merge:
  main.tf
Merge with strategy ort failed.
```

**Cause:** Local uncommitted changes to `main.tf` conflicted with incoming remote changes.

**Why it happens:** Git's merge strategy (`ort`) refuses to overwrite files that have unsaved local edits to protect you from losing work. When you run `git pull`, Git tries to merge the remote branch into your local branch. If the same file was changed both locally and remotely, Git cannot safely auto-merge without risking data loss — so it aborts.

**Fix:** Choose one of the following:
```bash
# Option 1 — Stash local changes, pull, then reapply
git stash
git pull origin master
git stash pop

# Option 2 — Discard local changes and take remote version
git checkout -- main.tf
git pull origin master

# Option 3 — Commit local changes first, then pull
git add main.tf
git commit -m "your message"
git pull origin master
```

---

## 2. Azure DevOps Pipeline — Missing Service Connection

**Error:**
```
Error: Input required: environmentServiceNameAzureRM
```

**Cause:** The `validate`, `plan`, and `apply` Terraform tasks in `azure-pipeline.yml` were missing the `environmentServiceNameAzureRM` input.

**Why it happens:** The `TerraformTask` extension requires an Azure Service Connection for any command that communicates with Azure (plan, apply, validate). This connection provides the credentials (Service Principal) that Terraform uses to authenticate against the Azure Resource Manager API. Without it, the task has no way to know which Azure subscription or identity to use, so it fails immediately before executing any Terraform command.

**Fix:** Added `environmentServiceNameAzureRM` to all three tasks in `azure-pipeline.yml`:
```yaml
- task: TerraformTask@5
  inputs:
    provider: 'azurerm'
    command: 'plan'
    commandOptions: '-out=tfplan'
    environmentServiceNameAzureRM: 'ado-2-azure'
```

> Ensure `ado-2-azure` matches the exact name of your Service Connection in Azure DevOps under **Project Settings → Service Connections**.

---

## 3. Invalid Resource Type Name in `main.tf`

**Error:**
```
Error: Invalid resource type name
  on main.tf line 26, in resource " resource_group" "rg":
  26: resource" resource_group" "rg" {
A name must start with a letter or underscore and may contain only letters, digits, underscores, and dashes.
```

**Cause:** Malformed resource block — a stray quote after `resource` and missing `azurerm_` prefix on the resource type.

**Why it happens:** Terraform's HCL syntax requires the `resource` keyword to be followed by a space and then a quoted string containing the full provider-prefixed resource type (e.g., `"azurerm_resource_group"`). When the quote is placed immediately after `resource` with no space, the parser reads `resource"` as an invalid token. Additionally, all Azure resource types must include the `azurerm_` prefix — it is how Terraform maps the resource to the correct provider plugin.

**Fix:**
```hcl
# Before (broken)
resource" resource_group" "rg" {

# After (fixed)
resource "azurerm_resource_group" "rg" {
```

---

## 4. Resource Group Not Found When Creating Virtual Network

**Error:**
```
Error: creating Virtual Network
ResourceGroupNotFound: Resource group 'terraform-rg' could not be found.
  with azurerm_virtual_network.vnet, on main.tf line 31
```

**Cause:** The VNet and subnet resources used hardcoded string `"terraform-rg"` instead of referencing the Terraform-managed resource group.

**Why it happens:** Terraform builds a dependency graph to determine the order in which resources are created. When you use a hardcoded string like `"terraform-rg"`, Terraform sees no relationship between the VNet and the resource group — so it may try to create both in parallel or create the VNet before the resource group exists. Azure then returns a `ResourceGroupNotFound` error because the target resource group hasn't been provisioned yet. Using resource references (e.g., `azurerm_resource_group.rg.name`) tells Terraform explicitly that the VNet depends on the RG, enforcing the correct creation order.

**Fix:** Replace hardcoded strings with resource references and add `depends_on`:
```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/26"]
}
```

**Additional fix — Invalid CIDR `10.0.0.0/32`:**
A `/32` prefix means only a single IP address, which is not a valid address space for a Virtual Network. Azure requires a CIDR range large enough to accommodate subnets. Corrected to `10.1.0.0/16`, which provides 65,536 addresses and fits the subnet `10.1.0.0/26`.


## 5. Do You Need `terraform.tfvars` When Using Environment-Specific `.tfvars` Files?

**Question:** If we have `environments/dev.tfvars`, `environments/test.tfvars`, and `environments/prod.tfvars`, do we still need a root `terraform.tfvars`?

**Answer:** No — and keeping both causes confusion.

**How Terraform loads variable files:**

| File | Loaded automatically? |
|---|---|
| `terraform.tfvars` | **Yes** — Terraform auto-loads this on every run without being asked |
| `environments/test.tfvars` | **No** — must be passed explicitly via `-var-file=` |

**Why it's a problem:** If both exist, running:
```bash
terraform apply -var-file=environments/test.tfvars
```
causes Terraform to load `terraform.tfvars` first (auto), then `environments/test.tfvars` on top. The env file wins for duplicate variables, but any variable only defined in `terraform.tfvars` silently bleeds into your test deployment — making the environment boundary unreliable.

**Fix:** Delete (or rename to `terraform.tfvars.example`) the root `terraform.tfvars` and always deploy with an explicit env file:
```bash
terraform apply -var-file=environments/dev.tfvars
terraform apply -var-file=environments/test.tfvars
terraform apply -var-file=environments/prod.tfvars
```

This makes the environment selection explicit, auditable, and safe — there are no hidden defaults that could accidentally bleed between environments.

---

## 6. How Environment-Specific Deployment Works in Azure Pipelines

### Overview

The pipeline in `azure-pipeline.yml` has three stages: **Dev → Test → Prod**. Each stage deploys to its own isolated environment using a dedicated `.tfvars` file and a separate Terraform state file.

```
master push → Dev (auto) → Test (manual approval) → Prod (manual approval)
```

---

### The .tfvars Files

Each environment has its own file under `environments/`:

| File | Environment |
|---|---|
| `environments/dev.tfvars` | Dev — smaller/cheaper SKUs |
| `environments/test.tfvars` | Test — mirrors prod sizing |
| `environments/prod.tfvars` | Prod — larger SKUs |

Key differences per environment:

| Variable | dev | test | prod |
|---|---|---|---|
| `vm_size` | `Standard_B2s` | `Standard_D2s_v3` | `Standard_D4s_v3` |
| `os_disk_size_gb` | 64 | 128 | 256 |
| `vnet_address_space` | `10.1.0.0/16` | `10.2.0.0/16` | `10.3.0.0/16` |

Each environment uses a **different CIDR range** to avoid network overlap, and its **own state file** so environments never overwrite each other.

---

### How Each Stage Loads Its Environment

**Stage-level variables** override the top-level defaults:
```yaml
- stage: Test
  variables:
    varFile: 'environments/test.tfvars'
    stateKey: 'test/terraform.tfstate'
```

The `plan` step then passes the correct var file:
```yaml
commandOptions: '-var-file=$(varFile) -var="admin_password=$(TF_VAR_admin_password)" -out=tfplan-test'
```

The `init` step points to the correct state file:
```yaml
backendAzureRmKey: $(stateKey)
```

This means:
- Dev reads `environments/dev.tfvars` and writes state to `dev/terraform.tfstate`
- Test reads `environments/test.tfvars` and writes state to `test/terraform.tfstate`
- Prod reads `environments/prod.tfvars` and writes state to `prod/terraform.tfstate`

---

### Manual Approval Gates (Test & Prod)

Test and Prod use a `deployment:` job type with an `environment:` name instead of a regular `job:`:
```yaml
- deployment: TerraformProd
  environment: 'prod'
```

This hooks into **ADO → Pipelines → Environments**. Steps to set up the approval gate:

1. Go to **Azure DevOps → Pipelines → Environments**
2. Create environments named `test` and `prod` (matching the pipeline YAML exactly)
3. Click the environment → **Approvals and checks → + Add → Approvals**
4. Add the required approvers

Once configured, the pipeline pauses before Test and Prod and waits for a human to click **Approve** before proceeding.

---

### Storing the Admin Password Securely

`admin_password` is never stored in any `.tfvars` file. It is passed via a **secret pipeline variable**:

1. Go to **ADO → Pipelines → your pipeline → Edit → Variables**
2. Add variable: `TF_VAR_admin_password` → enter value → check **Keep this value secret**
3. The pipeline passes it to Terraform at runtime: `-var="admin_password=$(TF_VAR_admin_password)"`

The secret is masked in all pipeline logs and never written to the state file in plaintext.

---

### Common Pipeline Issues

**Issue:** Stage variable `$(varFile)` resolves to the top-level default instead of the stage override.

**Cause:** Variable groups or queue-time variables can shadow stage-level variables.

**Fix:** Ensure the variable is defined directly under `variables:` in the stage block, not in a linked variable group with the same name.

---

**Issue:** `Init` in Test/Prod fails with `Error: Backend configuration changed`.

**Cause:** Terraform cached the previous backend config (from Dev's state key) in the `.terraform/` directory. Since the agent reuses workspace, the cached key conflicts with the new one.

**Fix:** Add `-reconfigure` to the init command options:
```yaml
commandOptions: '-reconfigure'
```

Or clear the `.terraform/` directory between stages using a script step:
```yaml
- script: rm -rf .terraform
  displayName: 'Clean Terraform cache'
```
