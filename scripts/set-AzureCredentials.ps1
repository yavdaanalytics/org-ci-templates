# ============================================================
# CONFIGURATION (CHANGE THESE)
# ============================================================
$Org            = "<GITHUB_ORG_NAME>"
$Repo           = "*"        # "*" = all repos, or set to a specific repo name
$Branch         = "main"
$AppName        = "github-actions-appservice"
$ResourceGroup  = "<RESOURCE_GROUP_NAME>"
$SubscriptionId = "<SUBSCRIPTION_ID>"

# ============================================================
# PREREQUISITE CHECKS
# ============================================================
Write-Host "Checking Azure login..."
az account show | Out-Null

Write-Host "Checking GitHub login..."
gh auth status | Out-Null

az account set --subscription $SubscriptionId

# ============================================================
# 1. CREATE AZURE AD APP REGISTRATION
# ============================================================
Write-Host "Creating Azure AD App Registration..."

$App = az ad app create `
  --display-name $AppName `
  | ConvertFrom-Json

$AppId    = $App.appId
$TenantId = (az account show | ConvertFrom-Json).tenantId

Write-Host "AppId: $AppId"

# ============================================================
# 2. CREATE SERVICE PRINCIPAL
# ============================================================
Write-Host "Creating Service Principal..."

az ad sp create `
  --id $AppId `
  | Out-Null

# ============================================================
# 3. ASSIGN RBAC ROLE (Contributor on Resource Group)
# ============================================================
Write-Host "Assigning RBAC role..."

az role assignment create `
  --assignee $AppId `
  --role "Contributor" `
  --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup" `
  | Out-Null

# ============================================================
# 4. CREATE FEDERATED OIDC CREDENTIAL
# ============================================================
Write-Host "Creating OIDC Federated Credential..."

$FederatedSubject = "repo:$Org/$Repo:ref:refs/heads/$Branch"

Write-Host "OIDC Subject: $FederatedSubject"

$FederatedCredential = @"
{
  "name": "github-oidc-$Repo-$Branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "$FederatedSubject",
  "audiences": ["api://AzureADTokenExchange"]
}
"@

$FederatedCredential | Out-File federated.json -Encoding utf8

az ad app federated-credential create `
  --id $AppId `
  --parameters federated.json `
  | Out-Null

Remove-Item federated.json -Force

# ============================================================
# 5. CREATE GITHUB ORG SECRETS (OIDC-CORRECT)
# ============================================================
Write-Host "Saving GitHub org-level OIDC secrets..."

$AppId | gh secret set AZURE_CLIENT_ID `
  --org $Org `
  --app actions

$TenantId | gh secret set AZURE_TENANT_ID `
  --org $Org `
  --app actions

$SubscriptionId | gh secret set AZURE_SUBSCRIPTION_ID `
  --org $Org `
  --app actions

# ============================================================
# DONE
