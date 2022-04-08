targetScope = 'resourceGroup'

@description('The name of the environment that the app should be deployed to.')
param environmentName string
param location string = resourceGroup().location
param frontEndImage string = 'mcr.microsoft.com/azuredocs/azure-vote-front:v1'
param backEndImage string = 'mcr.microsoft.com/oss/bitnami/redis:6.0.8'

param version string = '1.0'
param previous_version string = ''

param previous_split int = 100
param latest_split int = 0

var revisionSuffix = replace(version, '.', '-')

resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

var appName='azure-vote'
var appFe='${appName}-front'
var appBe='${appName}-back'
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
      containers: [
        {
          name: appFe
          image: frontEndImage
          env: [
            {
              name: 'REDIS'
              value: 'localhost'
            }
          ]
          resources: {
            cpu: json('.25')
            memory: '.5Gi'
          }
        }
        {
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
      ]
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
