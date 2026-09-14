locals {
  resource_prefix = "${var.name_prefix}-${var.environment}"
  common_tags = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      workload    = "aks"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.resource_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-${local.resource_prefix}-aks"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-${local.resource_prefix}-aks"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name  = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${local.resource_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

resource "azurerm_container_registry" "this" {
  name                = replace("acr${var.name_prefix}${var.environment}", "-", "")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${local.resource_prefix}-aks"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${local.resource_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "aks-${local.resource_prefix}"
  kubernetes_version  = var.kubernetes_version

  role_based_access_control_enabled = true
  local_account_disabled             = true
  azure_policy_enabled               = true
  oidc_issuer_enabled                = true
  workload_identity_enabled         = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  default_node_pool {
    name                        = "system"
    vm_size                     = "Standard_DS2_v2"
    vnet_subnet_id              = azurerm_subnet.aks.id
    node_count                  = 1
    only_critical_addons_enabled = false
    os_sku                      = "AzureLinux"
    temporary_name_for_rotation = "rotate"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = []
  }

  api_server_access_profile {
    authorized_ip_ranges = var.admin_allowed_ip_ranges
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  tags = local.common_tags

  depends_on = [azurerm_subnet_network_security_group_association.aks]
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${local.resource_prefix}-aks"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}