param location string = 'australiaeast'
param env string = 'dev'

module infra '../../main.bicep' = {
  name: 'infra-dev'
  params: {
    location: location
    env: env
  }
}
