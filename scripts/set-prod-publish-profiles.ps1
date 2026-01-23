# ------------------------------------
# CONFIG
# ------------------------------------
$Org = "yavdaanalytics"
$AppServiceName = "<YOUR_APP_SERVICE_NAME>"  # Appservice name
$RepoName = "<YOUR_REPO_NAME>"              # Repo name
# ------------------------------------
# AUTH CHECK (fail fast)
# ------------------------------------
az account show | Out-Null
gh auth status  | Out-Null
# ------------------------------------


try {
    # ------------------------------------
    # FIND RESOURCE GROUP FOR APP SERVICE
    # ------------------------------------
    $ResourceGroup = az webapp list `
        --query "[?name=='$AppServiceName'].resourceGroup | [0]" `
        -o tsv

    if (-not $ResourceGroup) {
        throw "App Service '$AppServiceName' not found in subscription"
    }

    Write-Host "Resource RG : $ResourceGroup"

    # ------------------------------------
    # GET PUBLISH PROFILE
    # ------------------------------------
    $PublishProfile = az webapp deployment list-publishing-profiles `
        --name $AppServiceName `
        --resource-group $ResourceGroup `
        --xml

    if (-not $PublishProfile) {
        throw "Failed to retrieve publish profile"
    }

    # ------------------------------------
    # SET GITHUB SECRET
    # ------------------------------------
    Write-Host "Setting PROD_PUBLISH_PROFILE secret..."

    $PublishProfile | gh secret set PROD_PUBLISH_PROFILE `
        --repo "$Org/$RepoName" `
        --app actions

    Write-Host "✅ Success for $RepoName"
}
catch {
    Write-Host "❌ Failed for $RepoName"
    Write-Host $_.Exception.Message
}

