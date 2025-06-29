output "eventhub_name" {
  description = "Eventhub name used for Observe collection."
  value       = azurerm_eventhub.observe_eventhub.name
}

output "eventhub_namespace_id" {
  description = "Resource ID of the eventhub namespace used for Observe collection."
  value       = azurerm_eventhub_namespace.observe_eventhub_namespace.id
}
output "function_url" {
  description = "Function URL used for Observe collection."
  value       = var.func_url
}

output "outbound_ip_address_list" {
  value = azurerm_linux_function_app.observe_collect_function_app.possible_outbound_ip_address_list
}
