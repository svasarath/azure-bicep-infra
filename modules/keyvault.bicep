// ============================================================
// modules/keyvault.bicep
// ============================================================

param env         string
param location    string
param projectName string
param tags        object
param subnetId    string

var kvName = 'kv-${projectName}-${env}-${uniqueString(resourceGroup().id)}'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name     : kvName
  location : location
  tags     : tags
  properties: {
    sku            : { family: 'A'  name: 'standard' }
    tenantId       : subscription().tenantId
    enableRbacAuthorization     : true     // Use RBAC, NOT legacy access policies
    enableSoftDelete            : true
    softDeleteRetentionInDays   : env == 'prod' ? 90 : 7
    enablePurgeProtection       : env == 'prod' ? true : null
    publicNetworkAccess         : 'Enabled'
    networkAcls: {
      bypass        : 'AzureServices'
      defaultAction : env == 'prod' ? 'Deny' : 'Allow'
      virtualNetworkRules: env == 'prod' ? [
        { id: subnetId  ignoreMissingVnetServiceEndpoint: false }
      ] : []
    }
  }
}

output keyVaultName string = kv.name
output keyVaultUri  string = kv.properties.vaultUri
