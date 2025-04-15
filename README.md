# Observe Azure Collection

This module which streamlines collection from multiple sources within Azure. 

It creates three functions responsible for data collection: 

`event_hub_telemetry_func` - captures the data sent to the Event Hub from the Azure resources Diagnostic settings. Event Hub triggers this function and forwards the data to Observe.

`timer_resources_func` - returns all resources within the location (region) and the corresponding metadata. It runs on an assigned NCRONTAB schedule and set to every 10 minutes by default.

`timer_vm_metrics_func` - returns virtual machine metrics from the hypervisor. It runs on an assigned NCRONTAB schedule and set to every 5 minutes by default.

## Data Collection Module Installation

1. Install [Azure's CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   
2. Ensure Azure CLI is properly installed by logging into Azure
     ```
    az login
    ```
    You should receive a token from your browser that looks like:
    ```
    [
      {
        "cloudName": "AzureCloud",
        "homeTenantId": "########-####-####-####-############",
        "id": "########-####-####-####-############",
        "isDefault": true,
        "managedByTenants": [],
        "name": "Acme Inc",
        "state": "Enabled",
        "tenantId": "########-####-####-####-############",
        "user": {
          "name": "joe@somecompany.com",
          "type": "user"
        }
      }
    ]
    ```
3.  Install [Azure's Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cmacos%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools)

4. Clone Observe's Terraform Collection Module ([terraform-azure-collection](https://github.com/observeinc/terraform-azure-collection)) repo locally
```
    git clone git@github.com:observeinc/terraform-azure-collection.git
```

5. Assign Application Variables

    Inside the root of the terraform-azure-collection create a file named **`azure.auto.tfvars`**. The contents of that file will be:

```
observe_customer = "<OBSERVE_CUSTOMER_ID>"
observe_token = "<DATASTREAM_INGEST_TOKEN>"
observe_domain = "<OBSERVE_DOMAIN(i.e. observe-staging.com)>"
timer_resources_func_schedule = "<TIMER_TRIGGER_FUNCTION_SCHEDULE>" 
timer_vm_metrics_func_schedule = "<TIMER_TRIGGER_FUNCTION_SCHEDULE>"
location = "<AZURE_REGIONAL_NAME>"
```

> Note: Default values are assigned for **`timer_resources_func_schedule`** and **`timer_vm_metrics_func_schedule`**, both based on **[NCRONTAB](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=in-process&pivots=programming-language-csharp#ncrontab-examples)**
>
> **`location`'s** value is [Azure's Regional Name](https://azuretracks.com/2021/04/current-azure-region-names-reference/) and is "eastus" by default

6. Deploy the Application
   
   Inside the root directory of the terraform-azure-collection module run the following commands:

  ```
      terraform init
      terraform apply -auto-approve
  ```

Collection should begin shortly

## Azure Resource Configuration

To receive logs and metrics for resources please add the appropriate diagnostic settings to each.  See "Azure Resource Configuration" section in [Observe's Azure Integration page](https://docs.observeinc.com/en/latestcontent/integrations/azure/azure.html) for more info.


## Removing Observe's Azure Collection Module ##

1. Remove the terraform-azure-collection module by running the following in the root directory:
```
    terraform destroy
```
>Note: You may encounter the following bug in the Azure provider during your destroy:
```
  Error: Deleting service principal with object ID "########-####-####-####-############", got status 403
  
  ServicePrincipalsClient.BaseClient.Delete(): unexpected status 403 with OData error:
  Authorization_RequestDenied: Insufficient privileges to complete the operation.
```
>If this happens execute simply remove the azuread_service_principal.observe_service_principal from terraform state and continue the destroy.

1. Find the service_principal object name by using the id returned.  i.e. (replace with your id)
```
  terraform state list -id=249783e5-bcfd-480b-b8e8-5f8aaa7452e8
```

2. Remove the object from state.  Make sure to wrap the object in single quotes. i.e. (replace name with that returned in previous step.)
```
  terraform state rm 'module.collection["eastus"].azuread_service_principal.observe_service_principal' 
```

3. Re-perform the terraform destroy 
```
  terraform destroy
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.86.0, <4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 3.0.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.116.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.observe_app_registration](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.observe_password](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.observe_service_principal](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_eventhub.observe_eventhub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub) | resource |
| [azurerm_eventhub_authorization_rule.observe_eventhub_access_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_eventhub_namespace.observe_eventhub_namespace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace) | resource |
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_secret.observe_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.observe_token](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_function_app.observe_collect_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_monitor_diagnostic_setting.observe_collect_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_resource_group.observe_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.observe_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_service_plan.observe_service_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.observe_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azurerm_eventhub_namespace_authorization_rule.root_namespace_access_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/eventhub_namespace_authorization_rule) | data source |
| [azurerm_subscription.primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | Additional app settings | `map(string)` | <pre>{<br>  "FEATURE_FLAGS": ""<br>}</pre> | no |
| <a name="input_func_url"></a> [func\_url](#input\_func\_url) | Observe Collect Function source URL zip | `string` | `"https://observeinc.s3.us-west-2.amazonaws.com/azure/azure-collection-functions-0.11.5.zip"` | no |
| <a name="input_function_app_debug_logs"></a> [function\_app\_debug\_logs](#input\_function\_app\_debug\_logs) | Enables routing of function app logs to eventhub for debugging eventhub & function app | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure Location to deploy resources | `string` | `"eastus"` | no |
| <a name="input_location_abbreviation"></a> [location\_abbreviation](#input\_location\_abbreviation) | A unique, short abbreviation to use for each location when assiging names to resources | `map(string)` | <pre>{<br>  "asiapacific": "ap",<br>  "australia": "as",<br>  "australiacentral": "ac",<br>  "australiacentral2": "ac2",<br>  "australiaeast": "ae",<br>  "australiasoutheast": "ase",<br>  "brazil": "b",<br>  "brazilsouth": "bs",<br>  "brazilsoutheast": "bse",<br>  "canada": "c",<br>  "canadacentral": "cc",<br>  "canadaeast": "ce",<br>  "centralindia": "ci",<br>  "centralus": "cu",<br>  "centraluseuap": "cue",<br>  "centralusstage": "cus",<br>  "eastasia": "ea",<br>  "eastasiastage": "eas",<br>  "eastus": "eu",<br>  "eastus2": "eu2",<br>  "eastus2euap": "eu2e",<br>  "eastus2stage": "eu2s",<br>  "eastusstage": "eus",<br>  "eastusstg": "eustg",<br>  "europe": "e",<br>  "france": "f",<br>  "francecentral": "fc",<br>  "francesouth": "fs",<br>  "germany": "g",<br>  "germanynorth": "gn",<br>  "germanywestcentral": "gwc",<br>  "global": "glob",<br>  "india": "i",<br>  "japan": "j",<br>  "japaneast": "je",<br>  "japanwest": "jw",<br>  "jioindiacentral": "jic",<br>  "jioindiawest": "jiw",<br>  "korea": "k",<br>  "koreacentral": "kc",<br>  "koreasouth": "ks",<br>  "northcentralus": "ncu",<br>  "northcentralusstage": "ncus",<br>  "northeurope": "ne",<br>  "norway": "n",<br>  "norwayeast": "nwe",<br>  "norwaywest": "nww",<br>  "qatarcentral": "qc",<br>  "singapore": "s",<br>  "southafrica": "sa",<br>  "southafricanorth": "san",<br>  "southafricawest": "saw",<br>  "southcentralus": "scu",<br>  "southcentralusstage": "scus",<br>  "southcentralusstg": "sctg",<br>  "southeastasia": "sea",<br>  "southeastasiastage": "sas",<br>  "southindia": "si",<br>  "swedencentral": "sc",<br>  "switzerland": "sz",<br>  "switzerlandnorth": "sn",<br>  "switzerlandwest": "sw",<br>  "uae": "uae",<br>  "uaecentral": "uc",<br>  "uaenorth": "un",<br>  "uk": "uk",<br>  "uksouth": "us",<br>  "ukwest": "uw",<br>  "unitedstates": "us",<br>  "unitedstateseuap": "use",<br>  "westcentralus": "wcu",<br>  "westeurope": "we",<br>  "westindia": "wi",<br>  "westus": "wu",<br>  "westus2": "wu2",<br>  "westus2stage": "wu2s",<br>  "westus3": "wu3",<br>  "westusstage": "wus"<br>}</pre> | no |
| <a name="input_observe_customer"></a> [observe\_customer](#input\_observe\_customer) | Observe customer id | `string` | n/a | yes |
| <a name="input_observe_domain"></a> [observe\_domain](#input\_observe\_domain) | Observe domain | `string` | `"observeinc.com"` | no |
| <a name="input_observe_token"></a> [observe\_token](#input\_observe\_token) | Observe ingest token | `string` | n/a | yes |
| <a name="input_prevent_rg_deletion"></a> [prevent\_rg\_deletion](#input\_prevent\_rg\_deletion) | Prevent resource group deletion if resource group is not empty.  Defaults to true. | `bool` | `true` | no |
| <a name="input_timer_resources_func_schedule"></a> [timer\_resources\_func\_schedule](#input\_timer\_resources\_func\_schedule) | Eventhub name to use for resources function | `string` | `"0 */10 * * * *"` | no |
| <a name="input_timer_vm_metrics_func_schedule"></a> [timer\_vm\_metrics\_func\_schedule](#input\_timer\_vm\_metrics\_func\_schedule) | Eventhub name to use for vm metrics function | `string` | `"30 */5 * * * *"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventhub_name"></a> [eventhub\_name](#output\_eventhub\_name) | Eventhub name used for Observe collection. |
| <a name="output_eventhub_namespace_id"></a> [eventhub\_namespace\_id](#output\_eventhub\_namespace\_id) | Resource ID of the eventhub namespace used for Observe collection. |
| <a name="output_function_url"></a> [function\_url](#output\_function\_url) | Function URL used for Observe collection. |
<!-- END_TF_DOCS -->