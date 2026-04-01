param env string
param location string
param projectName string
param tags object

var storageAccountName = 'st${projectName}${env}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: env == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: env == 'prod' ? 30 : 7
    }
  }
}

resource artifactsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: blobService
  name: 'artifacts'
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
