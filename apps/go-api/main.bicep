targetScope = 'resourceGroup'

@description('The name of the environment that the app should be deployed to.')
param environmentName string
param location string = resourceGroup().location
param image string

resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: environmentName
}

resource go 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'go'
  location: location

  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      registries: []
      ingress: {
        external: false
        targetPort: 80
      }
    }

    template: {
      containers: [
        {
          name: 'go-api'
          image: image
          resources: {
            cpu: json('0.25')
            memory: '.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
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
