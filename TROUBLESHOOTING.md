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
