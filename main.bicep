targetScope = 'subscription'

param nameseed string = uniqueString(subscription().id)
param location string = deployment().location

var rgName = 'containerapps-${nameseed}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: {
    'Automation': 'PurgeContentsAtMidnight'
  }
}

module env 'env/environment.bicep' = {
  name: 'env'
  scope: rg
  params: {
    nameseed: nameseed
    location: location
  }
}

param CreateManagedRedis bool =false
module redis 'misc/redis.bicep' = if(CreateManagedRedis) {
  name: '${deployment().name}-redis'
  scope: rg
  params: {
    logId: env.outputs.logResourceId
    nameSeed: nameseed
    location: location
  }
}

module app 'apps/azurevote/main.bicep' = {
  name: 'azure-vote'
  scope: resourceGroup(rgName)
  params: {
    location: location
    environmentName: env.outputs.environmentName
    redisName: CreateManagedRedis ? redis.name : ''
    UseExternalRedis: CreateManagedRedis
  }
}
