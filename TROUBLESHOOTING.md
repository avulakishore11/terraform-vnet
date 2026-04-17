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

**Cause:** The `validate`, `plan`, and `apply` Terraform tasks in `azure-pipeline.yml` were missing the `environmentServiceNameAzureRM` input, which is required for any task that authenticates against Azure.

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

**Cause:** The VNet and subnet resources used hardcoded string `"terraform-rg"` instead of referencing the Terraform-managed resource group, so Terraform had no way to infer the dependency order.

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

**Additional fix:** Corrected invalid CIDR `10.0.0.0/32` (single IP — unusable as a VNet address space) to `10.1.0.0/16`.
