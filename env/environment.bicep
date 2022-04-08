targetScope = 'resourceGroup'

param nameseed string = uniqueString(subscription().id)
param location string = resourceGroup().location

param UseVirtualNetwork bool = true

param vnetName string = 'vnet-${nameseed}'
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = if(UseVirtualNetwork) {
  name: vnetName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'controlplane'
        properties: {
          addressPrefix: '10.0.8.0/21'
        }
      }
      {
        name: 'app'
        properties: {
          addressPrefix: '10.0.16.0/21'
        }
      }
    ]
  }
}

resource logs 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'log-${nameseed}'
  location: location

  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}
output logResourceId string = logs.id

param environemntName string = 'cenv-${nameseed}'
resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: environemntName
  location: location

  properties: {
    vnetConfiguration: UseVirtualNetwork ? {
      internal: false
      infrastructureSubnetId: vnet.properties.subnets[0].id
      runtimeSubnetId: vnet.properties.subnets[1].id
    } : {}

    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
  }
}
output environmentName string = environment.name

output environment_id string = environment.id
