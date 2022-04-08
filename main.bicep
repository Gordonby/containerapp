targetScope = 'subscription'

param nameseed string = uniqueString(subscription().id)
param location string = deployment().location

var rgName = 'containerapps-${nameseed}'

module env 'env/main.bicep' = {
  name: 'env'
  params: {
    nameseed: nameseed
    resourceGroupName: rgName
    location: location
  }
}

module app 'apps/azurevote/main.bicep' = {
  name: 'azure-vote'
  scope: resourceGroup(rgName)
  params: {
    location: location
    environmentName: env.outputs.envName
  }
}
