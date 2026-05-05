# bootstrap.ps1
# Run this ONCE before 'terraform init' to create the backend storage account.
# Requires: Azure CLI logged in (az login)

$RESOURCE_GROUP  = "rg-tf-state"
$STORAGE_ACCOUNT = "terrastatesa"
$CONTAINER       = "tfstate"
$LOCATION        = "eastus"

Write-Host "`n==> Checking Azure CLI login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in. Running az login..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "Logged in as: $($account.user.name) | Subscription: $($account.name)" -ForegroundColor Green

# Get current user/service principal object ID for RBAC assignment
$currentObjectId = az ad signed-in-user show --query id -o tsv 2>$null
if (-not $currentObjectId) {
    # Fallback for service principals
    $currentObjectId = az account show --query "user.assignedIdentityInfo" -o tsv
}

Write-Host "`n==> Creating resource group: $RESOURCE_GROUP" -ForegroundColor Cyan
az group create `
    --name $RESOURCE_GROUP `
    --location $LOCATION `
    --output table

Write-Host "`n==> Creating storage account: $STORAGE_ACCOUNT" -ForegroundColor Cyan
az storage account create `
    --name $STORAGE_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --location $LOCATION `
    --sku Standard_LRS `
    --kind StorageV2 `
    --allow-blob-public-access false `
    --min-tls-version TLS1_2 `
    --output table

Write-Host "`n==> Enabling versioning on storage account (for state file safety)..." -ForegroundColor Cyan
az storage account blob-service-properties update `
    --account-name $STORAGE_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --enable-versioning true `
    --output table

Write-Host "`n==> Creating blob container: $CONTAINER" -ForegroundColor Cyan
az storage container create `
    --name $CONTAINER `
    --account-name $STORAGE_ACCOUNT `
    --auth-mode login `
    --output table

# Assign 'Storage Blob Data Contributor' so Terraform (use_azuread_auth=true) can read/write state
if ($currentObjectId) {
    Write-Host "`n==> Assigning 'Storage Blob Data Contributor' role to current identity..." -ForegroundColor Cyan
    $storageId = az storage account show `
        --name $STORAGE_ACCOUNT `
        --resource-group $RESOURCE_GROUP `
        --query id -o tsv

    az role assignment create `
        --role "Storage Blob Data Contributor" `
        --assignee $currentObjectId `
        --scope $storageId `
        --output table
} else {
    Write-Host "`n[!] Could not determine current identity — assign 'Storage Blob Data Contributor' manually on the storage account." -ForegroundColor Yellow
}

Write-Host "`n==> Bootstrap complete. Running terraform init..." -ForegroundColor Green
terraform init

Write-Host "`nDone. You can now run: terraform plan / terraform apply" -ForegroundColor Green
