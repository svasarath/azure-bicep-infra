param env string
param location string
param projectName string
param tags object

var vnetName = 'vnet-${projectName}-${env}'
var appSubnetName = 'snet-app-${projectName}-${env}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: appSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
              locations: [ location ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [ location ]
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output appSubnetId string = '${vnet.id}/subnets/${appSubnetName}'
