# Container App

## Getting started

```bash
echo "creating environment"
az deployment sub create -f .\main.bicep -l canadacentral -n azvoteapp
```

## Done

- Bicep IaC
- Deployment of 2 apps
- Go http api with internal ingress
- C# http api with external ingress
- C# http has dependency on the go api
- Configuration via Bicep to set env variable
- Configuration via Bicep to set env variable via Secret
- C# update revision via app workflow
- C# update env variables via app workflow
- Go update env variables via app workflow
- Traffic splitting
- scale to and from 0
- vnet integration

## TODO / missing
- Azure Vote sample app deployment
- queue example
- akv for secrets
- roll back revision
- end to end tls (custom certs)
- ui
- visualise scaling
- MSI
- private endpoints
- view of current instance