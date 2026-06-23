data "azurerm_client_config" "current" {}

# Resource Group

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# Azure Container Registry

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku           = "Premium"
  admin_enabled = false

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# AKS

resource "azurerm_kubernetes_cluster" "aks" {

  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dns_prefix = "${var.aks_name}-dns"

  kubernetes_version = var.kubernetes_version

  sku_tier = "Standard"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D4s_v5"
    auto_scaling_enabled = true

    node_count = 2
    min_count  = 2
    max_count  = 5

    os_disk_size_gb = 128
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# ACR Pull Permission

resource "azurerm_role_assignment" "acr_pull" {

  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"

  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  skip_service_principal_aad_check = true
}