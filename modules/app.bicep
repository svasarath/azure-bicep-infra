param env string
param location string
param projectName string
param tags object
param subnetId string
param keyVaultName string
param storageAccountName string

// Max 50 chars, alphanumeric only
var acrName = 'acr${take(projectName, 8)}${take(env, 4)}${take(uniqueString(resourceGroup().id), 8)}'
var appPlanName = 'plan-${projectName}-${env}'
var appName = 'app-${projectName}-${env}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: env == 'prod' ? 'Premium' : 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: env == 'prod' ? 'Enabled' : 'Disabled'
    policies: {
      retentionPolicy: {
        days: env == 'prod' ? 30 : 7
        status: 'enabled'
      }
    }
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appPlanName
  location: location
  tags: tags
  sku: {
    name: env == 'prod' ? 'P2v3' : 'B2'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${projectName}:latest'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acr.properties.loginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'ConnectionStrings__Default'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=db-connection-string)'
        }
        {
          name: 'Storage__AccountName'
          value: storageAccountName
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=appinsights-key)'
        }
      ]
      ipSecurityRestrictions: env == 'prod' ? [
        {
          action: 'Allow'
          priority: 100
          name: 'Allow-VNet'
          vnetSubnetResourceId: subnetId
        }
        {
          action: 'Deny'
          priority: 200
          name: 'Deny-All'
          ipAddress: 'Any'
        }
      ] : []
    }
    virtualNetworkSubnetId: subnetId
  }
}

output appServiceName string = appService.name
output appServicePrincipalId string = appService.identity.principalId
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
