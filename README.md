## Prerequisites

Observe's Azure collection requires the following to be installed locally:
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure's Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cmacos%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools)

## Installation

**Clone this repo locally**

```
    git clone git@github.com:observeinc/terraform-azure-collection.git
```

**Assign Applicaiton Variables**

Inside root of this repo and crate a file named `azure.auto.tfvars`. The contents of that file should be:
```
    observe_customer = "<OBSERVE_CUSTOMER_ID>"
    observe_token = "<DATASTREAM_INGEST_TOKEN>"
    observe_domain = "<OBSERVE_DOMAIN(i.e. observe-staging.com)>"
    timer_resources_func_schedule = "<TIMER_TRIGGER_FUNCTION_SCHEDULE>" 
    timer_vm_metrics_func_schedule = "<TIMER_TRIGGER_FUNCTION_SCHEDULE>"
    location = "<AZURE_REGIONAL_NAME>"
```
> Note: Default values are assigned for `timer_resources_func_schedule` and `timer_vm_metrics_func_schedule`, both based on [NCRONTAB](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=in-process&pivots=programming-language-csharp#ncrontab-examples)
>
> `location`'s value is Azure's Retional [Name](https://azuretracks.com/2021/04/current-azure-region-names-reference/) and is "eastus" by default.

**Login to Azure with CLI**

```
    az login
```

**Deploy the Application**

```
    terraform init
    terraform apply -auto-approve
```

Collection should begin shortly

**Removing the Application**

```
    terraform destroy
```
>Note: You may encounter the following bug in the Azure provider during your destroy:
```
  Error: Deleting service principal with object ID "########-####-####-####-############", got status 403
  
  ServicePrincipalsClient.BaseClient.Delete(): unexpected status 403 with OData error:
  Authorization_RequestDenied: Insufficient privileges to complete the operation.
```
>If this happens execute simply remove the azuread_service_principal.observe_service_principal from terraform state and coninue the destroy
```
  terraform state rm azuread_service_principal.observe_service_principal
  terraform destroy
```
  
