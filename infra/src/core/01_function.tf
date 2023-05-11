resource "azurerm_resource_group" "app_rg" {
  name     = "${local.project}-app-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "app" {
  name                     = replace("${local.project}appsa", "-", "")
  resource_group_name      = azurerm_resource_group.app_rg.name
  location                 = azurerm_resource_group.app_rg.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  tags = var.tags
}

resource "azurerm_service_plan" "app" {
  name                = "${local.project}-app-plan"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = var.tags
}

resource "azurerm_linux_function_app" "app" {
  name                = "${local.project}-app-fn"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location

  storage_account_name       = azurerm_storage_account.app.name
  storage_account_access_key = azurerm_storage_account.app.primary_access_key
  service_plan_id            = azurerm_service_plan.app.id

  https_only = true

  site_config {
    app_scale_limit                        = 2
    http2_enabled                          = true
    health_check_path                      = "/info"
    minimum_tls_version                    = "1.2"
    application_insights_connection_string = azurerm_application_insights.application_insights.connection_string

    application_stack {
      node_version = "18"
    }

    cors {
      allowed_origins = [
        "www.pagopa.it",
        "io.italia.it",
        "www.pagopa.gov.it",
      ]
    }

  }

  app_settings = {
    FUNCTIONS_WORKER_PROCESS_COUNT = "4"
    NODE_ENV                       = "production"
    AzureWebJobsDisableHomepage    = "true"
    SLOT_TASK_HUBNAME = "ProductionTaskHub"

    // Keepalive fields are all optionals
    FETCH_KEEPALIVE_ENABLED             = "true"
    FETCH_KEEPALIVE_SOCKET_ACTIVE_TTL   = "110000"
    FETCH_KEEPALIVE_MAX_SOCKETS         = "40"
    FETCH_KEEPALIVE_MAX_FREE_SOCKETS    = "10"
    FETCH_KEEPALIVE_FREE_SOCKET_TIMEOUT = "30000"
    FETCH_KEEPALIVE_TIMEOUT             = "60000"

    // Mailup groups and lists
    MAILUP_ALLOWED_GROUPS = "30,31,32,21,29,40,41,42,43,44,47,48,49,50,51"
    MAILUP_ALLOWED_LISTS  = "2,4,6"
    
  }

  sticky_settings {
    app_setting_names = [
      "SLOT_TASK_HUBNAME",
    ]
  }

  tags = var.tags
}
