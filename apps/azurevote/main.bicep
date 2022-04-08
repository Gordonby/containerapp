targetScope = 'resourceGroup'

@description('The name of the container apps environment that the app should be deployed to.')
param environmentName string

param location string = resourceGroup().location

@description('Azure vote frontend image tag')
param frontEndImage string = 'mcr.microsoft.com/azuredocs/azure-vote-front:v1'

@description('Azure vote backend image tag')
param backEndImage string = 'mcr.microsoft.com/oss/bitnami/redis:6.0.8'

@description('Have you created an Azure Redis Cache to use with the app?')
param UseExternalRedis bool = false

@description('Name of the Azure Redis Cache')
param managedRedisName string = ''

param version string = '1.0'
param previous_version string = ''

param previous_split int = 100
param latest_split int = 0

var revisionSuffix = replace(version, '.', '-')

resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

resource managedRedis 'Microsoft.Cache/redis@2020-12-01' existing = if(UseExternalRedis) {
  name: managedRedisName
}

var appName='azure-vote'
var appFe='${appName}-front'
var appBe='${appName}-back'

var frontendContainer = {
  name: appFe
  image: frontEndImage
  env: [
    {
      name: 'REDIS'
      value: UseExternalRedis ? managedRedis.properties.hostName : 'localhost'
    }
    {
      name: 'REDIS_PWD'
      value: UseExternalRedis ? managedRedis.listKeys().primaryKey : ''
    }
  ]
  resources: {
    cpu: json('.25')
    memory: '.5Gi'
  }
}

var backendContainer = {
  name: appBe
  image: backEndImage
  env: [
    {
      name: 'ALLOW_EMPTY_PASSWORD'
      value: 'yes'
    }
  ]
  resources: {
    cpu: json('.25')
    memory: '.5Gi'
  }
}

@description('Conditionally create Redis if an external Redis is not available')
var containers = UseExternalRedis ? array(frontendContainer) : concat(array(frontendContainer), array(backendContainer))

resource azureVote 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'azurevote-app'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      registries: []
      ingress: {
        external: true
        targetPort: 80
        traffic: [
          {
            revisionName: empty(previous_version) ? '${appName}--${revisionSuffix}' : previous_version
            weight: previous_split
          }
          {
            revisionName: '${appName}--${revisionSuffix}'
            weight: latest_split
          }
      ]
      }
    }
    template: {
      revisionSuffix: revisionSuffix
      containers: containers
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
