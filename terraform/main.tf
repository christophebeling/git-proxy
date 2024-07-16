provider "azurerm" {
  features {}
  skip_provider_registration = true
}

locals {
  linux_fx_version = "DOCKER|${azurerm_container_registry.git_proxy.login_server}/${var.acr_repository}:${var.acr_image_tag}"
}

output "linux_fx_version_output" {
  value = local.linux_fx_version
}

terraform {
  backend "azurerm" {
    resource_group_name   = "asy-github-proxy"
    storage_account_name  = "gitproxytfstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

data "azurerm_resource_group" "git_proxy" {
  name = var.resource_group_name
}

resource "azurerm_container_registry" "git_proxy" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.git_proxy.name
  location            = data.azurerm_resource_group.git_proxy.location
  sku                 = "Standard"
  admin_enabled       = false  // Use Managed Identities instead of admin credentials
}

resource "azurerm_service_plan" "git_proxy" {
  name                = var.app_service_plan_name
  location            = data.azurerm_resource_group.git_proxy.location
  resource_group_name = data.azurerm_resource_group.git_proxy.name
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "git_proxy" {
  name                = var.app_service_name
  resource_group_name = data.azurerm_resource_group.git_proxy.name
  location            = data.azurerm_resource_group.git_proxy.location
  service_plan_id     = azurerm_service_plan.git_proxy.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name = "${var.acr_name}:${var.acr_image_tag}"
      docker_registry_url = "https://${azurerm_container_registry.git_proxy.login_server}"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"  // Example setting
    "WEBSITES_PORT"   = "8000"
    "GIT_PROXY_UI_HOST" = "https://git-proxy-appservice.azurewebsites.net"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_linux_web_app.git_proxy.identity.0.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.git_proxy.id
}

output "app_service_principal_id" {
  value = azurerm_linux_web_app.git_proxy.identity.0.principal_id
}

output "acr_id" {
  value = azurerm_container_registry.git_proxy.id
}
