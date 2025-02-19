param uniqueId string
param prefix string
param useFakeContainerImage bool = false
param userAssignedIdentityResourceId string
param userAssignedIdentityClientId string
param openAiEndpoint string
param openAiApiKey string = ''
param cosmosDbEndpoint string
param cosmosDbDatabase string
param cosmosDbContainer string
param applicationInsightsConnectionString string
param containerRegistry string = '${prefix}acr${uniqueId}'
param location string = resourceGroup().location
param logAnalyticsWorkspaceName string
param chatContainerImage string = useFakeContainerImage ? '${containerRegistry}.azurecr.io/realtime-callcenter-chat:latest' : 'mcr.microsoft.com/azure-cognitive-services/language/language-understanding:latest'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

// see https://azureossd.github.io/2023/01/03/Using-Managed-Identity-and-Bicep-to-pull-images-with-Azure-Container-Apps/
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: '${prefix}-containerAppEnv-${uniqueId}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource uiContainerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: '${prefix}-chat-${uniqueId}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      registries: [
        {
          server: '${containerRegistry}.azurecr.io'
          identity: userAssignedIdentityResourceId
        }
      ]
    }
    template: {
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      containers: [
        {
          name: 'ui'
          image: chatContainerImage
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            { name: 'AZURE_CLIENT_ID', value: userAssignedIdentityClientId }
            { name: 'APPLICATIONINSIGHTS_CONNECTIONSTRING', value: applicationInsightsConnectionString }
            { name: 'AZURE_OPENAI_ENDPOINT', value: openAiEndpoint }
            { name: 'AZURE_OPENAI_DEPLOYMENT', value: 'gpt-4o-realtime-preview' }
            { name: 'AZURE_OPENAI_API_KEY', value: openAiApiKey }
            { name: 'COSMOSDB_ENDPOINT', value: cosmosDbEndpoint }
            { name: 'COSMOSDB_DATABASE', value: cosmosDbDatabase }
            { name: 'COSMOSDB_CONTAINER', value: cosmosDbContainer }
          ]
        }
      ]
    }
  }
}
