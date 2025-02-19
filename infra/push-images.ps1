# PowerShell version of a script to push Docker images to Azure Container Registry
# Helpful when you just want to add a new tag to an existing image and push it to ACR without all the complexity of a CI/CD pipeline

param (
    [string]$RG,
    [string]$ACR_NAME,
    [string[]]$Apps = @("chat"),
    [bool]$askForConfirmation = $false
)

# Ensure current working directory is parent of "infra" folder
$deploymentPath = (Get-Location).Path
if (-not (Test-Path -Path "$deploymentPath/infra")) {
    Write-Host "Please run this script from the parent directory of the 'infra' folder" -ForegroundColor Red
    exit
}

# Generating a unique build tag using the current date and time
$BUILD_ID = Get-Date -Format "yyyyMMddHHmmss"
$TAG = "build-$BUILD_ID"

# If $ACR_NAME is not provided, query the resource group for the ACR name not containing 'ml'
if (-not $ACR_NAME) {
    $ACR_NAME = az acr list --resource-group $RG --query "[? contains(name, 'acr')].name" -o tsv
}

write-host "Using Azure Container Registry: $ACR_NAME"

# Function to deploy container app
function DeployContainerApp($dockerImageName, $dockerFile, $sourceFolder, $tag, $containerAppName) {

    if ($askForConfirmation) {
        $confirmation = Read-Host -Prompt "Do you want to proceed with the build of $dockerImageName ? (Y/N)"
    } else {
        $confirmation = "Y"
    }
    if ($confirmation -eq "Y" -or $confirmation -eq "y") {
        Write-Host "Building the $containerAppName Docker image using Azure Container Registry with tag $tag..." -ForegroundColor Green
        az acr build --registry $ACR_NAME `
            --resource-group $RG `
            --image ${dockerImageName}:$tag `
            --image "${dockerImageName}:latest" `
            --file $dockerFile $sourceFolder

        # Update the container app to pull the latest image and restart
        Write-Host "Updating the Azure Container App ($containerAppName) to pull the latest image..." -ForegroundColor Yellow
        az containerapp update --name $containerAppName --resource-group $RG --image ${dockerImageName}:$tag

        Write-Host "$dockerImageName build completed and deployed to Azure Container App $containerAppName" -ForegroundColor Green
    } else {
        Write-Host "$dockerImageName build skipped by the user." -ForegroundColor Yellow
    }
}

# Get container app names from the Azure Container App
$containerAppNames = az containerapp list --resource-group $RG --query "[].name" -o tsv

# Assign container app names to variables
$UI_WEB_APP_NAME = $containerAppNames | Where-Object { $_ -like "*chat-*" }

Write-Host "Container app names are: $UI_WEB_APP_NAME, $API_WEB_APP_NAME, $FUNC_WEB_APP_NAME, $AGENTS_WEB_APP_NAME"

# Define a dictionary for app configurations
$appConfigs = @{
    "chat" = @{
        "dockerImageName" = "$ACR_NAME.azurecr.io/realtime-callcenter-chat"
        "dockerFile" = "Dockerfile"
        "sourceFolder" = "."
        "containerAppName" = $UI_WEB_APP_NAME
    }
}

# Deploy web apps based on the input list
foreach ($app in $Apps) {
    if ($appConfigs.ContainsKey($app)) {
        $config = $appConfigs[$app]
        DeployContainerApp $config.dockerImageName $config.dockerFile $config.sourceFolder $TAG $config.containerAppName
    } else {
        Write-Host "No configuration found for app: $app" -ForegroundColor Red
    }
}
