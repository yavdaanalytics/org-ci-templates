# ============================================================
# CONFIGURATION (CHANGE THESE)
# ============================================================
$Org            = "<GITHUB_ORG_NAME>"
$Repo           = "<GITHUB_REPO_NAME>"        # use "*" for all repos in org
$Branch         = "main"
$AppName        = "<APP_NAME>"
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
# 3. ASSIGN RBAC ROLE (Contributor on RG)
# ============================================================
Write-Host "Assigning RBAC role..."

az role assignment create `
  --assignee $AppId `
  --role "Contributor" `
  --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup" `
  | Out-Null

# ============================================================
# 4. CREATE FEDERATED OIDC CREDENTIAL
#    (ALL REPOS IN ORG, MAIN BRANCH)
# ============================================================
Write-Host "Creating OIDC Federated Credential..."

$FederatedCredentialObject = @{ 
  name     = "github-org-main"
  issuer   = "https://token.actions.githubusercontent.com"
  subject  = ("repo:{0}/{1}:ref:refs/heads/{2}" -f $Org, $Repo, $Branch)
  audiences = @("api://AzureADTokenExchange")
}

$FederatedCredential = $FederatedCredentialObject | ConvertTo-Json -Depth 3

$FederatedCredential | Out-File federated.json -Encoding utf8

az ad app federated-credential create `
  --id $AppId `
  --parameters federated.json `
  | Out-Null

Remove-Item federated.json -Force

# ============================================================
# 5. CREATE AZURE_CREDENTIALS JSON
# ============================================================
Write-Host "Generating AZURE_CREDENTIALS JSON..."

$AzureCredentials = @{
  clientId       = $AppId
  tenantId       = $TenantId
  subscriptionId = $SubscriptionId
} | ConvertTo-Json -Compress

# ============================================================
# 6. SAVE AZURE_CREDENTIALS AS GITHUB ORG SECRET
# ============================================================
Write-Host "Saving AZURE_CREDENTIALS as GitHub org secret..."

$AzureCredentials | gh secret set AZURE_CREDENTIALS `
  --org $Org `
  --app actions

# ============================================================
# DONE
# ============================================================
Write-Host "=============================================="
Write-Host "✅ BOOTSTRAP COMPLETE"
Write-Host "Azure AD App        : $AppName"
Write-Host "Client ID           : $AppId"
Write-Host "OIDC Scope          : repo:$Org/$Repo:ref:refs/heads/$Branch"
Write-Host "GitHub Secret       : AZURE_CREDENTIALS (org-level)"
Write-Host "=============================================="
