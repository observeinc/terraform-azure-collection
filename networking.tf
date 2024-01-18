
# Create a virtual network and a subnet for private endpoint to live in
resource "azurerm_virtual_network" "observe_vnet" {
  name                = "observeVnet-${var.observe_customer}-${var.location}-${local.sub}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
}

## Used for Delegation for Function App 
resource "azurerm_subnet" "observe_subnet2" {
  name                 = "observeSubNet2-${var.observe_customer}-${var.location}-${local.sub}"
  resource_group_name  = azurerm_resource_group.observe_resource_group.name
  virtual_network_name = azurerm_virtual_network.observe_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  private_endpoint_network_policies_enabled = true

   delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/networkinterfaces/*"]
    }
  }
  
}

##Used for Pvt Endpoint 
resource "azurerm_subnet" "observe_subnet" {
  name                 = "observeSubNet-${var.observe_customer}-${var.location}-${local.sub}"
  resource_group_name  = azurerm_resource_group.observe_resource_group.name
  virtual_network_name = azurerm_virtual_network.observe_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  private_endpoint_network_policies_enabled = true  
  
}


resource "azurerm_private_endpoint" "observe_pvt_endpoint" {
  name                = "observePvtEndpoint-${var.observe_customer}-${var.location}-${local.sub}"
  location            = azurerm_resource_group.observe_resource_group.location
  resource_group_name = azurerm_resource_group.observe_resource_group.name
  subnet_id           = azurerm_subnet.observe_subnet.id

  private_service_connection {
    name                           = "example-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.observe_storage_account.id
    subresource_names              = ["blob"] #Only allowed one per private endpoint 
    is_manual_connection           = false
  }

 lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }
}
