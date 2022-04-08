targetScope = 'subscription'

param nameseed string = uniqueString(subscription().id)
param resourceGroupName string = 'containerapps-${nameseed}'
param location string = deployment().location

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    'Automation': 'PurgeContentsAtMidnight'
  }
}
output rgName string = rg.name

module environment './environment.bicep' = {
  name: 'cenv-${nameseed}'
  scope: rg
  params: {
    location: location
  }
}
output envName string = environment.name
