targetScope = 'subscription'

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param env string = 'dev'

@description('Azure region')
param location string = 'australiaeast'

@description('Project name')
param projectName string = 'myapp'

@description('Principal ID of the GitHub Actions managed identity')
param githubActionsPrincipalId string

@description('Principal ID of the app managed identity')
param appPrincipalId string = ''

var resourceGroupName = 'rg-${projectName}-${env}'
var tags = {
  environment: env
  project: projectName
  managedBy: 'bicep'
}

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module network 'modules/network.bicep' = {
  name: 'network'
  scope: rg
  params: {
    env: env
    location: location
    projectName: projectName
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    env: env
    location: location
    projectName: projectName
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    env: env
    location: location
    projectName: projectName
    tags: tags
    subnetId: network.outputs.appSubnetId
  }
}

module app 'modules/app.bicep' = {
  name: 'app'
  scope: rg
  params: {
    env: env
    location: location
    projectName: projectName
    tags: tags
    subnetId: network.outputs.appSubnetId
    keyVaultName: keyvault.outputs.keyVaultName
    storageAccountName: storage.outputs.storageAccountName
  }
}

module iam 'modules/iam.bicep' = {
  name: 'iam'
  scope: rg
  params: {
    githubActionsPrincipalId: githubActionsPrincipalId
    appPrincipalId: appPrincipalId
    keyVaultName: keyvault.outputs.keyVaultName
    storageAccountName: storage.outputs.storageAccountName
    acrName: app.outputs.acrName
  }
}

output resourceGroupName string = rg.name
output appServiceName string = app.outputs.appServiceName
output keyVaultName string = keyvault.outputs.keyVaultName
output acrLoginServer string = app.outputs.acrLoginServer
output acrName string = app.outputs.acrName
