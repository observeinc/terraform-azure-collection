resource "azurerm_virtual_network" "observe_vnet" {
  name                = "observeVnet-${var.observe_customer}-${var.location}-${local.sub}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
}

#Delegated subnet for function app 
resource "azurerm_subnet" "observe_subnet" {
  name                 = "observeSubNet-${var.observe_customer}-${var.location}-${local.sub}"
  resource_group_name  = azurerm_resource_group.observe_resource_group.name
  virtual_network_name = azurerm_virtual_network.observe_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/networkinterfaces/*"]
    }
  }

  service_endpoints = ["Microsoft.Storage", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.Web"]

}