# NOTE: Azure Functions Core Tools must be installed locally
# https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cmacos%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools
locals {
  is_windows    = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  sleep_command = local.is_windows == true ? "Start-Sleep" : "sleep"
  region        = lookup(var.location_abbreviation, var.location, "none-found")
  keyvault_name = "${local.region}${var.observe_customer}${local.sub}"
  sub           = substr(data.azurerm_subscription.primary.subscription_id, -8, -1)
}

# Obtains current client config from az login, allowing terraform to run.
data "azuread_client_config" "current" {}

# Creates the alias of your Subscription to be used for association below.
data "azurerm_subscription" "primary" {}

# https://petri.com/understanding-azure-app-registrations/#:~:text=Azure%20App%20registrations%20are%20an,to%20use%20an%20app%20registration.
resource "azuread_application" "observe_app_registration" {
  display_name = "observeApp-${var.observe_customer}-${var.location}-${local.sub}"
  owners       = [data.azuread_client_config.current.object_id]
}

# Creates an auth token that is used by the app to call APIs.
resource "azuread_application_password" "observe_password" {
  application_id = azuread_application.observe_app_registration.id
}

# Creates a Service "Principal" for the "observe" app.
resource "azuread_service_principal" "observe_service_principal" {
  client_id = azuread_application.observe_app_registration.client_id
}

resource "azurerm_key_vault" "key_vault" {
  name                = local.keyvault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  tenant_id           = data.azuread_client_config.current.tenant_id

  sku_name = "standard"
  #public_network_access_enabled = "false"
  network_acls = {
    bypass = "None"
    default_action = "Deny"
    ip_rules = [
          "4.150.128.0/18",
          "4.150.192.0/19",
          "4.249.128.0/17",
          "13.67.128.0/20",
          "13.67.144.0/21",
          "13.67.152.0/24",
          "13.67.153.0/28",
          "13.67.153.32/27",
          "13.67.153.64/26",
          "13.67.153.128/25",
          "13.67.155.0/24",
          "13.67.156.0/22",
          "13.67.160.0/19",
          "13.67.192.0/18",
          "13.86.0.0/17",
          "13.89.0.0/16",
          "13.104.147.128/25",
          "13.104.219.128/25",
          "13.105.17.192/26",
          "13.105.24.0/24",
          "13.105.37.0/26",
          "13.105.53.192/26",
          "13.105.98.160/27",
          "13.105.98.192/28",
          "13.105.98.224/27",
          "13.105.101.48/28",
          "13.105.101.64/26",
          "20.9.0.0/17",
          "20.12.128.0/17",
          "20.15.128.0/17",
          "20.29.0.0/17",
          "20.33.13.0/24",
          "20.33.15.0/24",
          "20.33.73.0/24",
          "20.33.144.0/24",
          "20.33.159.0/24",
          "20.33.206.0/24",
          "20.33.226.0/23",
          "20.33.243.0/24",
          "20.33.247.0/24",
          "20.33.248.0/22",
          "20.37.128.0/18",
          "20.38.96.0/23",
          "20.38.122.0/23",
          "20.38.176.0/21",
          "20.40.192.0/18",
          "20.44.8.0/21",
          "20.46.224.0/19",
          "20.47.58.0/23",
          "20.47.78.0/23",
          "20.60.18.0/24",
          "20.60.30.0/23",
          "20.60.178.0/23",
          "20.60.194.0/23",
          "20.60.240.0/23",
          "20.60.244.0/23",
          "20.80.64.0/18",
          "20.83.0.0/18",
          "20.84.128.0/17",
          "20.95.16.0/24",
          "20.95.27.0/24",
          "20.95.48.0/24",
          "20.95.55.0/24",
          "20.95.59.0/24",
          "20.98.128.0/18",
          "20.106.0.0/18",
          "20.109.192.0/18",
          "20.112.192.0/18",
          "20.118.0.0/18",
          "20.118.192.0/18",
          "20.135.0.0/22",
          "20.135.188.0/22",
          "20.135.192.0/23",
          "20.136.3.128/25",
          "20.136.5.0/24",
          "20.143.4.0/24",
          "20.143.68.0/22",
          "20.150.43.128/25",
          "20.150.58.0/24",
          "20.150.63.0/24",
          "20.150.77.0/24",
          "20.150.89.0/24",
          "20.150.95.0/24",
          "20.153.22.0/24",
          "20.153.137.0/24",
          "20.157.34.0/23",
          "20.157.73.0/24",
          "20.157.88.0/24",
          "20.157.91.0/24",
          "20.157.142.0/23",
          "20.157.163.0/24",
          "20.157.184.0/24",
          "20.157.251.0/24",
          "20.184.64.0/18",
          "20.186.192.0/18",
          "20.190.134.0/24",
          "20.190.155.0/24",
          "20.201.200.0/22",
          "20.209.18.0/23",
          "20.209.36.0/23",
          "20.209.98.0/23",
          "20.209.142.0/23",
          "20.209.184.0/23",
          "20.221.0.0/17",
          "20.236.192.0/18",
          "23.99.128.0/17",
          "23.100.80.0/21",
          "23.100.240.0/20",
          "23.101.112.0/20",
          "23.102.202.0/24",
          "40.64.145.176/28",
          "40.64.163.0/25",
          "40.67.160.0/19",
          "40.69.128.0/18",
          "40.77.0.0/17",
          "40.77.130.128/26",
          "40.77.137.0/25",
          "40.77.138.0/25",
          "40.77.161.64/26",
          "40.77.166.192/26",
          "40.77.171.0/24",
          "40.77.175.192/27",
          "40.77.175.240/28",
          "40.77.182.16/28",
          "40.77.182.192/26",
          "40.77.184.128/25",
          "40.77.197.0/24",
          "40.77.255.128/26",
          "40.78.128.0/18",
          "40.78.221.0/24",
          "40.82.16.0/22",
          "40.82.96.0/22",
          "40.83.0.0/20",
          "40.83.16.0/21",
          "40.83.24.0/26",
          "40.83.24.64/27",
          "40.83.24.128/25",
          "40.83.25.0/24",
          "40.83.26.0/23",
          "40.83.28.0/22",
          "40.83.32.0/19",
          "40.86.0.0/17",
          "40.87.180.0/30",
          "40.87.180.4/31",
          "40.87.180.14/31",
          "40.87.180.16/30",
          "40.87.180.20/31",
          "40.87.180.28/30",
          "40.87.180.32/29",
          "40.87.180.42/31",
          "40.87.180.44/30",
          "40.87.180.48/28",
          "40.87.180.64/30",
          "40.87.180.74/31",
          "40.87.180.76/30",
          "40.87.180.80/28",
          "40.87.180.96/27",
          "40.87.180.128/26",
          "40.87.180.192/30",
          "40.87.180.202/31",
          "40.87.180.204/30",
          "40.87.180.208/28",
          "40.87.180.224/28",
          "40.87.180.240/29",
          "40.87.180.248/30",
          "40.87.181.4/30",
          "40.87.181.8/29",
          "40.87.181.16/28",
          "40.87.181.32/27",
          "40.87.181.64/26",
          "40.87.181.128/28",
          "40.87.181.144/29",
          "40.87.181.152/31",
          "40.87.181.162/31",
          "40.87.181.164/30",
          "40.87.181.168/29",
          "40.87.181.176/28",
          "40.87.181.192/26",
          "40.87.182.4/30",
          "40.87.182.8/29",
          "40.87.182.24/29",
          "40.87.182.32/28",
          "40.87.182.48/29",
          "40.87.182.56/30",
          "40.87.182.62/31",
          "40.87.182.64/26",
          "40.87.182.128/25",
          "40.87.183.0/28",
          "40.87.183.16/29",
          "40.87.183.24/30",
          "40.87.183.34/31",
          "40.87.183.36/30",
          "40.87.183.42/31",
          "40.87.183.44/30",
          "40.87.183.54/31",
          "40.87.183.56/29",
          "40.87.183.64/26",
          "40.87.183.144/28",
          "40.87.183.160/27",
          "40.87.183.192/27",
          "40.87.183.224/29",
          "40.87.183.232/30",
          "40.87.183.236/31",
          "40.87.183.244/30",
          "40.87.183.248/29",
          "40.89.224.0/19",
          "40.90.16.0/27",
          "40.90.21.128/25",
          "40.90.22.0/25",
          "40.90.26.128/25",
          "40.90.129.224/27",
          "40.90.130.64/28",
          "40.90.130.192/28",
          "40.90.132.192/26",
          "40.90.137.224/27",
          "40.90.140.96/27",
          "40.90.140.224/27",
          "40.90.141.0/27",
          "40.90.142.128/27",
          "40.90.142.240/28",
          "40.90.144.0/27",
          "40.90.144.128/26",
          "40.90.148.176/28",
          "40.90.149.96/27",
          "40.90.151.144/28",
          "40.90.154.64/26",
          "40.90.156.192/26",
          "40.90.158.64/26",
          "40.93.8.0/24",
          "40.93.13.0/24",
          "40.93.192.0/24",
          "40.97.7.0/24",
          "40.97.12.0/24",
          "40.97.55.64/26",
          "40.97.55.128/25",
          "40.113.192.0/18",
          "40.120.164.2/31",
          "40.120.164.4/30",
          "40.120.164.8/29",
          "40.120.164.16/29",
          "40.120.164.24/30",
          "40.120.164.36/30",
          "40.120.164.40/29",
          "40.120.164.48/29",
          "40.120.164.56/31",
          "40.120.164.66/31",
          "40.120.164.68/30",
          "40.120.164.72/30",
          "40.120.164.76/31",
          "40.120.164.80/28",
          "40.120.164.100/30",
          "40.120.164.104/29",
          "40.120.164.112/31",
          "40.120.164.118/31",
          "40.120.164.120/29",
          "40.120.164.128/27",
          "40.120.164.160/28",
          "40.120.164.176/31",
          "40.120.164.180/30",
          "40.120.164.184/30",
          "40.120.164.188/31",
          "40.120.164.196/30",
          "40.120.164.200/29",
          "40.120.164.208/28",
          "40.120.164.224/31",
          "40.120.164.228/30",
          "40.120.164.232/30",
          "40.120.164.236/31",
          "40.120.164.240/29",
          "40.120.164.250/31",
          "40.120.164.252/30",
          "40.120.165.0/25",
          "40.120.165.128/26",
          "40.120.165.192/27",
          "40.120.165.224/28",
          "40.120.165.240/31",
          "40.120.165.244/30",
          "40.120.165.248/29",
          "40.120.166.0/27",
          "40.120.166.32/30",
          "40.120.166.40/29",
          "40.120.166.48/28",
          "40.120.166.64/31",
          "40.120.166.68/30",
          "40.120.166.72/29",
          "40.120.166.80/28",
          "40.120.166.96/27",
          "40.120.166.128/26",
          "40.120.166.192/27",
          "40.120.166.224/30",
          "40.120.166.230/31",
          "40.120.166.232/29",
          "40.120.166.240/28",
          "40.120.167.0/26",
          "40.120.167.64/29",
          "40.120.167.72/30",
          "40.122.16.0/20",
          "40.122.32.0/19",
          "40.122.64.0/18",
          "40.122.128.0/17",
          "40.123.168.0/24",
          "40.123.169.0/30",
          "40.123.169.6/31",
          "40.123.169.8/29",
          "40.123.169.16/28",
          "40.123.169.32/27",
          "40.123.169.64/27",
          "40.123.169.96/29",
          "40.123.169.104/31",
          "40.123.169.108/30",
          "40.123.169.112/28",
          "40.123.169.140/30",
          "40.123.169.144/28",
          "40.123.169.160/27",
          "40.123.169.192/26",
          "40.123.170.0/29",
          "40.123.170.8/30",
          "40.123.170.12/31",
          "40.123.170.22/31",
          "40.123.170.24/29",
          "40.123.170.32/28",
          "40.123.170.52/30",
          "40.123.170.86/31",
          "40.123.170.88/29",
          "40.123.170.96/29",
          "40.123.170.104/30",
          "40.123.170.108/31",
          "40.123.170.116/30",
          "40.123.170.120/29",
          "40.123.170.130/31",
          "40.123.170.132/30",
          "40.123.170.136/29",
          "40.123.170.144/28",
          "40.123.170.160/28",
          "40.123.170.176/29",
          "40.123.170.184/31",
          "40.123.170.192/31",
          "40.123.170.196/30",
          "40.123.170.200/29",
          "40.123.170.208/29",
          "40.123.170.216/30",
          "40.123.170.220/31",
          "40.123.170.224/27",
          "40.123.171.0/24",
          "40.126.6.0/24",
          "40.126.27.0/24",
          "48.208.55.0/24",
          "48.208.56.0/23",
          "48.208.58.0/24",
          "48.214.128.0/17",
          "51.5.24.0/24",
          "51.5.255.240/28",
          "52.101.8.0/24",
          "52.101.32.0/22",
          "52.101.61.0/24",
          "52.101.62.0/23",
          "52.101.64.0/24",
          "52.102.130.0/24",
          "52.102.139.0/24",
          "52.103.4.0/24",
          "52.103.13.0/24",
          "52.103.130.0/24",
          "52.103.139.0/24",
          "52.106.0.0/24",
          "52.106.5.0/24",
          "52.106.10.0/23",
          "52.108.165.0/24",
          "52.108.166.0/23",
          "52.108.185.0/24",
          "52.108.208.0/21",
          "52.109.8.0/22",
          "52.111.227.0/24",
          "52.112.72.0/24",
          "52.112.113.0/24",
          "52.113.129.0/24",
          "52.114.128.0/22",
          "52.115.76.0/22",
          "52.115.88.0/22",
          "52.115.92.0/24",
          "52.123.2.0/24",
          "52.123.12.0/24",
          "52.123.185.0/24",
          "52.123.186.0/24",
          "52.125.128.0/22",
          "52.136.30.0/24",
          "52.141.192.0/19",
          "52.141.240.0/20",
          "52.143.193.0/24",
          "52.143.224.0/19",
          "52.154.0.0/18",
          "52.154.128.0/17",
          "52.158.160.0/20",
          "52.158.192.0/19",
          "52.165.0.0/19",
          "52.165.32.0/20",
          "52.165.48.0/28",
          "52.165.49.0/24",
          "52.165.56.0/21",
          "52.165.64.0/19",
          "52.165.96.0/21",
          "52.165.104.0/25",
          "52.165.128.0/17",
          "52.173.0.0/16",
          "52.176.0.0/17",
          "52.176.128.0/19",
          "52.176.160.0/21",
          "52.176.176.0/20",
          "52.176.192.0/19",
          "52.176.224.0/24",
          "52.180.128.0/19",
          "52.180.184.0/27",
          "52.180.184.32/28",
          "52.180.185.0/24",
          "52.182.128.0/17",
          "52.185.0.0/19",
          "52.185.32.0/20",
          "52.185.48.0/21",
          "52.185.56.0/26",
          "52.185.56.64/27",
          "52.185.56.96/28",
          "52.185.56.128/27",
          "52.185.56.160/28",
          "52.185.64.0/19",
          "52.185.96.0/20",
          "52.185.112.0/26",
          "52.185.112.96/27",
          "52.185.120.0/21",
          "52.189.0.0/17",
          "52.228.128.0/17",
          "52.230.128.0/17",
          "52.232.157.0/24",
          "52.238.192.0/18",
          "52.239.150.0/23",
          "52.239.177.32/27",
          "52.239.177.64/26",
          "52.239.177.128/25",
          "52.239.195.0/24",
          "52.239.234.0/23",
          "52.242.128.0/17",
          "52.245.68.0/24",
          "52.245.69.32/27",
          "52.245.69.64/27",
          "52.245.69.96/28",
          "52.245.69.144/28",
          "52.245.69.160/27",
          "52.245.69.192/26",
          "52.245.70.0/23",
          "52.255.0.0/19",
          "57.150.42.0/23",
          "57.150.96.0/23",
          "57.150.104.0/23",
          "57.150.128.0/23",
          "57.150.134.0/23",
          "57.150.140.0/22",
          "57.150.144.0/23",
          "57.150.160.0/23",
          "57.150.192.0/23",
          "64.236.0.0/17",
          "65.55.144.0/23",
          "65.55.146.0/24",
          "70.152.7.0/24",
          "70.152.91.0/24",
          "70.152.92.0/22",
          "70.152.96.0/21",
          "70.152.104.0/23",
          "72.152.0.0/17",
          "74.249.128.0/17",
          "104.43.128.0/17",
          "104.44.88.160/27",
          "104.44.91.160/27",
          "104.44.92.224/27",
          "104.44.94.80/28",
          "104.208.0.0/19",
          "104.208.32.0/20",
          "128.203.128.0/17",
          "130.131.128.0/17",
          "131.253.36.224/27",
          "135.233.0.0/17",
          "151.206.85.0/24",
          "151.206.86.0/24",
          "157.55.108.0/23",
          "168.61.128.0/25",
          "168.61.128.128/28",
          "168.61.128.160/27",
          "168.61.128.192/26",
          "168.61.129.0/25",
          "168.61.129.128/26",
          "168.61.129.208/28",
          "168.61.129.224/27",
          "168.61.130.64/26",
          "168.61.130.128/25",
          "168.61.131.0/26",
          "168.61.131.128/25",
          "168.61.132.0/26",
          "168.61.144.0/20",
          "168.61.160.0/19",
          "168.61.208.0/20",
          "172.168.0.0/15",
          "172.170.0.0/16",
          "172.171.0.0/19",
          "172.173.8.0/21",
          "172.173.64.0/18",
          "172.202.0.0/17",
          "172.212.128.0/17",
          "193.149.72.0/21",
          "2603:1030::/45",
          "2603:1030:9:2::/63",
          "2603:1030:9:4::/62",
          "2603:1030:9:8::/61",
          "2603:1030:9:10::/62",
          "2603:1030:9:14::/63",
          "2603:1030:9:17::/64",
          "2603:1030:9:18::/61",
          "2603:1030:9:20::/59",
          "2603:1030:9:40::/58",
          "2603:1030:9:80::/59",
          "2603:1030:9:a0::/60",
          "2603:1030:9:b3::/64",
          "2603:1030:9:b4::/63",
          "2603:1030:9:b7::/64",
          "2603:1030:9:b8::/63",
          "2603:1030:9:bd::/64",
          "2603:1030:9:be::/63",
          "2603:1030:9:c0::/58",
          "2603:1030:9:100::/64",
          "2603:1030:9:104::/62",
          "2603:1030:9:108::/62",
          "2603:1030:9:10c::/64",
          "2603:1030:9:111::/64",
          "2603:1030:9:112::/63",
          "2603:1030:9:114::/64",
          "2603:1030:9:118::/62",
          "2603:1030:9:11c::/63",
          "2603:1030:9:11f::/64",
          "2603:1030:9:120::/61",
          "2603:1030:9:128::/62",
          "2603:1030:9:12f::/64",
          "2603:1030:9:130::/60",
          "2603:1030:9:140::/59",
          "2603:1030:9:160::/61",
          "2603:1030:9:168::/62",
          "2603:1030:9:16f::/64",
          "2603:1030:9:170::/60",
          "2603:1030:9:180::/61",
          "2603:1030:9:18c::/62",
          "2603:1030:9:190::/60",
          "2603:1030:9:1a0::/59",
          "2603:1030:9:1c0::/60",
          "2603:1030:9:1d0::/62",
          "2603:1030:9:1d4::/63",
          "2603:1030:9:1d6::/64",
          "2603:1030:9:1db::/64",
          "2603:1030:9:1dc::/62",
          "2603:1030:9:1e0::/59",
          "2603:1030:9:200::/57",
          "2603:1030:9:280::/61",
          "2603:1030:9:288::/62",
          "2603:1030:9:28d::/64",
          "2603:1030:9:28e::/63",
          "2603:1030:9:290::/60",
          "2603:1030:9:2a0::/59",
          "2603:1030:9:2c0::/63",
          "2603:1030:9:2c2::/64",
          "2603:1030:9:2c4::/62",
          "2603:1030:9:2c8::/62",
          "2603:1030:9:2cc::/63",
          "2603:1030:9:2d4::/62",
          "2603:1030:9:2d8::/61",
          "2603:1030:9:2e0::/59",
          "2603:1030:9:300::/60",
          "2603:1030:9:310::/62",
          "2603:1030:9:314::/64",
          "2603:1030:9:319::/64",
          "2603:1030:9:31a::/63",
          "2603:1030:9:31c::/62",
          "2603:1030:9:320::/62",
          "2603:1030:9:324::/63",
          "2603:1030:9:328::/63",
          "2603:1030:9:339::/64",
          "2603:1030:9:33a::/63",
          "2603:1030:9:33c::/62",
          "2603:1030:9:340::/62",
          "2603:1030:9:344::/64",
          "2603:1030:9:348::/61",
          "2603:1030:9:350::/64",
          "2603:1030:9:352::/63",
          "2603:1030:9:354::/62",
          "2603:1030:9:358::/61",
          "2603:1030:9:360::/61",
          "2603:1030:9:368::/63",
          "2603:1030:9:36a::/64",
          "2603:1030:9:36e::/64",
          "2603:1030:9:370::/61",
          "2603:1030:9:378::/62",
          "2603:1030:9:37c::/64",
          "2603:1030:9:37e::/63",
          "2603:1030:9:380::/57",
          "2603:1030:9:400::/61",
          "2603:1030:9:408::/62",
          "2603:1030:9:40c::/63",
          "2603:1030:9:40f::/64",
          "2603:1030:9:410::/61",
          "2603:1030:9:418::/62",
          "2603:1030:9:420::/61",
          "2603:1030:9:428::/63",
          "2603:1030:9:42a::/64",
          "2603:1030:9:42f::/64",
          "2603:1030:9:430::/62",
          "2603:1030:9:434::/64",
          "2603:1030:9:436::/63",
          "2603:1030:9:438::/62",
          "2603:1030:9:43c::/63",
          "2603:1030:9:440::/62",
          "2603:1030:9:444::/63",
          "2603:1030:9:446::/64",
          "2603:1030:9:449::/64",
          "2603:1030:9:44a::/63",
          "2603:1030:9:44c::/62",
          "2603:1030:9:450::/60",
          "2603:1030:9:460::/62",
          "2603:1030:9:464::/63",
          "2603:1030:9:466::/64",
          "2603:1030:9:468::/62",
          "2603:1030:9:46c::/64",
          "2603:1030:9:470::/61",
          "2603:1030:9:478::/62",
          "2603:1030:9:47c::/63",
          "2603:1030:9:47e::/64",
          "2603:1030:9:480::/62",
          "2603:1030:9:484::/64",
          "2603:1030:9:486::/63",
          "2603:1030:9:488::/63",
          "2603:1030:9:48b::/64",
          "2603:1030:9:48c::/62",
          "2603:1030:9:490::/60",
          "2603:1030:9:4a0::/59",
          "2603:1030:9:4c0::/58",
          "2603:1030:9:500::/62",
          "2603:1030:9:504::/63",
          "2603:1030:9:506::/64",
          "2603:1030:9:508::/61",
          "2603:1030:9:510::/60",
          "2603:1030:9:522::/63",
          "2603:1030:9:524::/62",
          "2603:1030:9:528::/62",
          "2603:1030:9:52c::/63",
          "2603:1030:9:52e::/64",
          "2603:1030:9:530::/60",
          "2603:1030:9:540::/58",
          "2603:1030:9:581::/64",
          "2603:1030:9:582::/63",
          "2603:1030:9:584::/62",
          "2603:1030:9:588::/61",
          "2603:1030:9:590::/60",
          "2603:1030:9:5a0::/60",
          "2603:1030:9:5b0::/62",
          "2603:1030:a::/47",
          "2603:1030:d::/48",
          "2603:1030:10::/47",
          "2603:1030:13::/56",
          "2603:1030:13:200::/62",
          "2603:1036:903:7::/64",
          "2603:1036:903:8::/64",
          "2603:1036:903:36::/63",
          "2603:1036:903:38::/64",
          "2603:1036:2403::/48",
          "2603:1036:2500:1c::/64",
          "2603:1036:3000:100::/59",
          "2603:1037:1:100::/59",
          "2603:1061:1312:800::/54",
          "2603:1061:1312:3000::/54",
          "2603:1061:170a::/48",
          "2603:1061:2002:200::/57",
          "2603:1061:2004:7200::/57",
          "2603:1061:2010:6::/64",
          "2603:1061:2011:6::/64",
          "2603:1062:2:180::/57",
          "2603:1062:c:2a::/63",
          "2603:1063:11::/56",
          "2603:1063:110::/55",
          "2603:1063:110:200::/56",
          "2603:1063:210::/55",
          "2603:1063:406::/56",
          "2603:1063:607::/56",
          "2603:1063:2200:1c::/64",
          "2a01:111:f403:c111::/64",
          "2a01:111:f403:c904::/62",
          "2a01:111:f403:c928::/62",
          "2a01:111:f403:c92c::/64",
          "2a01:111:f403:d104::/62",
          "2a01:111:f403:d115::/64",
          "2a01:111:f403:d904::/62",
          "2a01:111:f403:d91b::/64",
          "2a01:111:f403:e004::/62",
          "2a01:111:f403:e01e::/64",
          "2a01:111:f403:f904::/62"
        ],
  }
}

resource "azurerm_key_vault_access_policy" "user" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id


  secret_permissions = [
    "Backup",
    "Restore",
    "Get",
    "Set",
    "List",
    "Delete",
    "Purge",
  ]
}

resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = lookup(azurerm_linux_function_app.observe_collect_function_app.identity[0], "principal_id")


  secret_permissions = [
    "Backup",
    "Restore",
    "Get",
    "Set",
    "List",
    "Delete",
    "Purge",
  ]
}

resource "azurerm_key_vault_secret" "observe_token" {
  name         = "observe-token"
  value        = var.observe_token
  key_vault_id = azurerm_key_vault.key_vault.id

  # Required so the user running this can get the result of the call.
  depends_on = [
    azurerm_key_vault_access_policy.user,
  ]
}

resource "azurerm_key_vault_secret" "observe_password" {
  name         = "observe-password"
  value        = azuread_application_password.observe_password.value
  key_vault_id = azurerm_key_vault.key_vault.id

  # Required so the user running this can get the result of the call.
  depends_on = [
    azurerm_key_vault_access_policy.user,
  ]
}


# Assigns the created service principal a role in current Azure Subscription.
# https://learn.microsoft.com/en-us/azure/azure-monitor/roles-permissions-security#monitoring-reader
# https://learn.microsoft.com/en-us/azure/azure-monitor/roles-permissions-security#security-considerations-for-monitoring-data
resource "azurerm_role_assignment" "observe_role_assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.observe_service_principal.object_id
}

resource "azurerm_resource_group" "observe_resource_group" {
  name     = "observeResources-${var.observe_customer}-${var.location}-${local.sub}"
  location = var.location
}

#
resource "azurerm_eventhub_namespace" "observe_eventhub_namespace" {
  name                = local.keyvault_name
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  sku                 = "Standard"
  capacity            = 2

  tags = {
    created_by = "Observe Terraform"
  }
}

resource "azurerm_eventhub" "observe_eventhub" {
  name                = "observeEventHub-${var.observe_customer}-${var.location}-${local.sub}"
  namespace_name      = azurerm_eventhub_namespace.observe_eventhub_namespace.name
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  partition_count     = 32
  message_retention   = 7
}

resource "azurerm_eventhub_authorization_rule" "observe_eventhub_access_policy" {
  name                = "observeAccessPolicy-${var.observe_customer}-${var.location}-${local.sub}"
  namespace_name      = azurerm_eventhub_namespace.observe_eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.observe_eventhub.name
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_service_plan" "observe_service_plan" {
  name                = "observeServicePlan-${var.observe_customer}${var.location}-${local.sub}"
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_storage_account" "observe_storage_account" {
  name                     = lower("${var.observe_customer}${local.region}${local.sub}")
  resource_group_name      = azurerm_resource_group.observe_resource_group.name
  location                 = azurerm_resource_group.observe_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Probably want to use ZRS when we got prime time
}

resource "azurerm_linux_function_app" "observe_collect_function_app" {
  name                = "observeApp-${var.observe_customer}-${var.location}-${local.sub}"
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  service_plan_id     = azurerm_service_plan.observe_service_plan.id

  storage_account_name       = azurerm_storage_account.observe_storage_account.name
  storage_account_access_key = azurerm_storage_account.observe_storage_account.primary_access_key

  app_settings = merge({
    WEBSITE_RUN_FROM_PACKAGE                      = var.func_url
    AzureWebJobsDisableHomepage                   = true
    OBSERVE_DOMAIN                                = var.observe_domain
    OBSERVE_CUSTOMER                              = var.observe_customer
    OBSERVE_TOKEN                                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.observe_token.id})"
    AZURE_TENANT_ID                               = data.azuread_client_config.current.tenant_id
    AZURE_CLIENT_ID                               = azuread_application.observe_app_registration.client_id
    AZURE_CLIENT_SECRET                           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.observe_password.id})"
    AZURE_CLIENT_LOCATION                         = lower(replace(var.location, " ", ""))
    timer_resources_func_schedule                 = var.timer_resources_func_schedule
    timer_vm_metrics_func_schedule                = var.timer_vm_metrics_func_schedule
    EVENTHUB_TRIGGER_FUNCTION_EVENTHUB_NAME       = azurerm_eventhub.observe_eventhub.name
    EVENTHUB_TRIGGER_FUNCTION_EVENTHUB_CONNECTION = "${azurerm_eventhub_authorization_rule.observe_eventhub_access_policy.primary_connection_string}"
    # Pending resolution of https://github.com/hashicorp/terraform-provider-azurerm/issues/18026
    # APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.observe_insights.instrumentation_key 
  }, var.app_settings)

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

#### Event Hub Debug 
data "azurerm_eventhub_namespace_authorization_rule" "root_namespace_access_policy" {
  name                = "RootManageSharedAccessKey"
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  namespace_name      = azurerm_eventhub_namespace.observe_eventhub_namespace.name
}

resource "azurerm_monitor_diagnostic_setting" "observe_collect_function_app" {
  count                          = var.function_app_debug_logs ? 1 : 0
  name                           = "observeAppDiagnosticSetting-${var.observe_customer}-${var.location}-${local.sub}"
  target_resource_id             = azurerm_linux_function_app.observe_collect_function_app.id
  eventhub_name                  = azurerm_eventhub.observe_eventhub.name
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.root_namespace_access_policy.id
  enabled_log {
    category = "FunctionAppLogs"
  }
  metric {
    category = "AllMetrics"
  }
}



# Pending resolution of https://github.com/hashicorp/terraform-provider-azurerm/issues/18026
resource "azurerm_application_insights" "observe_insights" {
  name                = "observeApplicationInsights"
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  application_type    = "web"
}
