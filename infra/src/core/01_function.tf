resource "azurerm_resource_group" "app_rg" {
  name     = "${local.project}-app-rg"
  location = var.location

  tags = var.tags
}

data "azurerm_key_vault_secret" "newsletter-MAILUP-CLIENT-ID" {
  name         = "newsletter-MAILUP-CLIENT-ID"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "newsletter-MAILUP-SECRET" {
  name         = "newsletter-MAILUP-SECRET"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "newsletter-MAILUP-USERNAME" {
  name         = "newsletter-MAILUP-USERNAME"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "newsletter-MAILUP-PASSWORD" {
  name         = "newsletter-MAILUP-PASSWORD"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "newsletter-RECAPTCHA-SECRET" {
  name         = "newsletter-RECAPTCHA-SECRET"
  key_vault_id = module.key_vault.id
}

resource "azurerm_storage_account" "app" {
  name                            = replace("${local.project}appsa", "-", "")
  resource_group_name             = azurerm_resource_group.app_rg.name
  location                        = azurerm_resource_group.app_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_service_plan" "app" {
  name                = "${local.project}-app-plan"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  os_type             = "Linux"
  sku_name            = "S1"

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
    always_on                              = true
    http2_enabled                          = true
    health_check_path                      = "/info"
    minimum_tls_version                    = "1.2"
    application_insights_connection_string = azurerm_application_insights.application_insights.connection_string

    application_stack {
      node_version = "18"
    }

    cors {
      allowed_origins = [
        "http://localhost:8000",
        "https://www.pagopa.it",
        "https://www.pagopa.gov.it",
        "https://io.italia.it",
        "https://firma.io.italia.it",
      ]
    }

    app_service_logs {
      disk_quota_mb         = 35
      retention_period_days = 7
    }

  }

  app_settings = {
    FUNCTIONS_WORKER_PROCESS_COUNT = "4"
    NODE_ENV                       = "production"
    AzureWebJobsDisableHomepage    = "true"
    SLOT_TASK_HUBNAME              = "ProductionTaskHub"

    // Keepalive fields are all optionals
    FETCH_KEEPALIVE_ENABLED             = "true"
    FETCH_KEEPALIVE_SOCKET_ACTIVE_TTL   = "110000"
    FETCH_KEEPALIVE_MAX_SOCKETS         = "40"
    FETCH_KEEPALIVE_MAX_FREE_SOCKETS    = "10"
    FETCH_KEEPALIVE_FREE_SOCKET_TIMEOUT = "30000"
    FETCH_KEEPALIVE_TIMEOUT             = "60000"

    // Mailup groups and lists
    MAILUP_ALLOWED_GROUPS = "30,31,32,21,29,40,41,42,43,44,47,48,49,50,51,61"
    MAILUP_ALLOWED_LISTS  = "2,4,6,7"

    // Mailup account
    MAILUP_CLIENT_ID = data.azurerm_key_vault_secret.newsletter-MAILUP-CLIENT-ID.value
    MAILUP_SECRET    = data.azurerm_key_vault_secret.newsletter-MAILUP-SECRET.value
    MAILUP_USERNAME  = data.azurerm_key_vault_secret.newsletter-MAILUP-USERNAME.value
    MAILUP_PASSWORD  = data.azurerm_key_vault_secret.newsletter-MAILUP-PASSWORD.value
    RECAPTCHA_SECRET = data.azurerm_key_vault_secret.newsletter-RECAPTCHA-SECRET.value

  }

  sticky_settings {
    app_setting_names = [
      "SLOT_TASK_HUBNAME",
    ]
  }

  tags = var.tags
}
