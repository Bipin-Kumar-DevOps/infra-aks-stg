output "resource_group_name" {
  description = "AKS resource group name."
  value       = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_get_credentials_command" {
  description = "Command to configure kubectl using Microsoft Entra credentials."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name}"
}

output "acr_login_server" {
  description = "ACR login server."
  value       = azurerm_container_registry.this.login_server
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.this.id
}