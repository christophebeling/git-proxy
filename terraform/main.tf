provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "git_proxy" {
  name = var.resource_group_name
}

resource "azurerm_container_registry" "git_proxy" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.git_proxy.name
  location            = data.azurerm_resource_group.git_proxy.location
  sku                 = "Standard"
}

resource "azurerm_app_service_plan" "git_proxy" {
  name                = var.app_service_plan_name
  location            = data.azurerm_resource_group.git_proxy.location
  resource_group_name = data.azurerm_resource_group.git_proxy.name
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "git_proxy" {
  name                = var.app_service_name
  location            = data.azurerm_resource_group.git_proxy.location
  resource_group_name = data.azurerm_resource_group.git_proxy.name
  app_service_plan_id = azurerm_app_service_plan.git_proxy.id

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.git_proxy.login_server}"
  }

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.git_proxy.login_server}/${var.acr_repository}:${var.acr_tag}"
  }

  https_only = true
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_app_service.git_proxy.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.git_proxy.id
}
