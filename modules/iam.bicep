param githubActionsPrincipalId string
param appPrincipalId string
param keyVaultName string
param storageAccountName string
param acrName string

var roles = {
  acrPush: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
  acrPull: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  kvSecretsUser: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  kvSecretsOfficer: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  storageBlobContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  storageBlobReader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource sa 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

// GitHub Actions — push images
resource githubAcrPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, githubActionsPrincipalId, roles.acrPush)
  scope: acr
  properties: {
    roleDefinitionId: roles.acrPush
    principalId: githubActionsPrincipalId
    principalType: 'ServicePrincipal'
    description: 'GitHub Actions — push container images'
  }
}

// GitHub Actions — manage KV secrets
resource githubKvOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, githubActionsPrincipalId, roles.kvSecretsOfficer)
  scope: kv
  properties: {
    roleDefinitionId: roles.kvSecretsOfficer
    principalId: githubActionsPrincipalId
    principalType: 'ServicePrincipal'
    description: 'GitHub Actions — manage Key Vault secrets'
  }
}

// GitHub Actions — storage artifacts
resource githubStorageContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sa.id, githubActionsPrincipalId, roles.storageBlobContributor)
  scope: sa
  properties: {
    roleDefinitionId: roles.storageBlobContributor
    principalId: githubActionsPrincipalId
    principalType: 'ServicePrincipal'
    description: 'GitHub Actions — upload/download build artifacts'
  }
}

// App Service — pull images
resource appAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(appPrincipalId)) {
  name: guid(acr.id, appPrincipalId, roles.acrPull)
  scope: acr
  properties: {
    roleDefinitionId: roles.acrPull
    principalId: appPrincipalId
    principalType: 'ServicePrincipal'
    description: 'App Service — pull container images'
  }
}

// App Service — read KV secrets
resource appKvSecrets 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(appPrincipalId)) {
  name: guid(kv.id, appPrincipalId, roles.kvSecretsUser)
  scope: kv
  properties: {
    roleDefinitionId: roles.kvSecretsUser
    principalId: appPrincipalId
    principalType: 'ServicePrincipal'
    description: 'App Service — read secrets at runtime'
  }
}

// App Service — read blobs
resource appStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(appPrincipalId)) {
  name: guid(sa.id, appPrincipalId, roles.storageBlobReader)
  scope: sa
  properties: {
    roleDefinitionId: roles.storageBlobReader
    principalId: appPrincipalId
    principalType: 'ServicePrincipal'
    description: 'App Service — read blobs at runtime'
  }
}
