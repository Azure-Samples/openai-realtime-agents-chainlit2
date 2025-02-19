// Main deployment parameters
param uniqueId string = uniqueString(resourceGroup().id)
param prefix string = 'dev'
param location string = resourceGroup().location
param openAIName string
param openAIResourceGroupName string
param useFakeContainerImage bool = false

module uami './uami.bicep' = {
  name: 'uami'
  params: {
    uniqueId: uniqueId
    prefix: prefix
    location: location
  }
}

module appin './appin.bicep' = {
  name: 'appin'
  params: {
    uniqueId: uniqueId
    prefix: prefix
    location: location
    userAssignedIdentityPrincipalId: uami.outputs.principalId
  }
}

// Reference to the ACR module, assuming the file is named 'acr.bicep' and located in the same directory
module acrModule './acr.bicep' = {
  name: 'acr'
  params: {
    uniqueId: uniqueId
    prefix: prefix
    userAssignedIdentityPrincipalId: uami.outputs.principalId
    location: location
  }
}

module openAI './openAI.bicep' = {
  name: 'openAI'
  scope: resourceGroup(openAIResourceGroupName)
  params: {
    openAIName: openAIName
    userAssignedIdentityPrincipalId: uami.outputs.principalId
  }
}

module cosmosdb './cosmos.bicep' = {
  name: 'cosmosdb'
  params: {
    uniqueId: uniqueId
    prefix: prefix
    location: location
    userAssignedIdentityPrincipalId: uami.outputs.principalId
  }
}

module aca './aca.bicep' = {
  name: 'aca'
  params: {
    uniqueId: uniqueId
    prefix: prefix
    userAssignedIdentityResourceId: uami.outputs.identityId
    containerRegistry: acrModule.outputs.acrName
    location: location
    logAnalyticsWorkspaceName: appin.outputs.logAnalyticsWorkspaceName
    applicationInsightsConnectionString: appin.outputs.applicationInsightsConnectionString
    openAiApiKey: '' // openAI.listKeys().key1
    openAiEndpoint: openAI.outputs.openAIEndpoint
    userAssignedIdentityClientId: uami.outputs.clientId
    cosmosDbContainer: cosmosdb.outputs.cosmosDbContainer
    cosmosDbDatabase: cosmosdb.outputs.cosmosDbDatabase
    cosmosDbEndpoint: cosmosdb.outputs.cosmosDbEndpoint
    useFakeContainerImage: useFakeContainerImage
  }
}
