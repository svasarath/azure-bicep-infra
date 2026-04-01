param location string = resourceGroup().location
param env string

module vnet './modules/network/vnet.bicep' = {
  name: 'vnet-deploy'
  params: {
    location: location
    env: env
  }
}

module storage './modules/storage/storage.bicep' = {
  name: 'storage-deploy'
  params: {
    location: location
    env: env
  }
}

module keyvault './modules/security/keyvault.bicep' = {
  name: 'kv-deploy'
  params: {
    location: location
    env: env
  }
}

module iam './modules/security/iam.bicep' = {
  name: 'iam-deploy'
  params: {
    env: env
    storageId: storage.outputs.id
    principalId: keyvault.outputs.identityPrincipalId
  }
}
