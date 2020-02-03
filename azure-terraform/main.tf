data "azurerm_client_config" "current" {}

terraform {
  required_version = ">= 0.12.0"
  required_providers {
    azurerm = ">=1.30.0"
  }
}

provider "azurerm" {
  version = ">=1.30.0"

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

locals {
  domain = var.application

  shared_tags = {
    application  = var.application
    deployment   = "terraform"
  }

  app_tags = merge(local.shared_tags, { "environment" = var.environment })
}

resource "azurerm_resource_group" "resource_group" {
  location = var.location
  name     = local.domain
  tags     = local.app_tags
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${local.domain}VirtualNetwork"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "subnet" {
  name                 = "${local.domain}Subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${local.domain}storageaccount"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  tags                     = local.app_tags
}


resource "azurerm_app_service_plan" "app_service_plan_function" {
  name                = "${local.domain}AppServicePlanFunctions"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  kind                = "FunctionApp"

  sku {
    size = "S1"
    tier = "Standard"
  }

  tags = local.app_tags
}

resource "azurerm_function_app" "function_app" {
  name                = "${local.domain}FunctionApp"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  storage_connection_string = azurerm_storage_account.storage_account.primary_connection_string
  app_service_plan_id = azurerm_app_service_plan.app_service_plan_function.id

  app_settings = {
    # Runtime configuration
    FUNCTIONS_WORKER_RUNTIME        = "node"
    WEBSITE_NODE_DEFAULT_VERSION    = "~10"
    # Azure Functions configuration
    KeyVaultName                    = azurerm_key_vault.key_vault.name
    StorageConnectionString         = azurerm_storage_account.storage_account.primary_connection_string
    ServiceBusConnectionString      = azurerm_servicebus_namespace.servicebus_namespace.default_primary_connection_string
    ServiceBusQueueName             = azurerm_servicebus_queue.servicebus_queue.name
  }

  identity {
    type = "SystemAssigned" # to access to the KeyVault
  }

  # set up git deployment
  provisioner "local-exec" {
    command = "az functionapp deployment source config --resource-group ${azurerm_resource_group.resource_group.name} --branch master --manual-integration --name MyFunctionApp --repo-url ${var.github_address_fonction_app}"
  }

  tags = local.app_tags
}


resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = "${local.domain}Servicebus"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "Standard"
  tags                = local.app_tags
}

resource "azurerm_servicebus_queue" "servicebus_queue" {
  name                = "${local.domain}ServicebusQueueClientData"
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  enable_partitioning = true
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "${local.domain}Keyvault"
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = azurerm_resource_group.resource_group.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.service_principal_object_id

    key_permissions = [
      "get",
      "list",
      "create",
      "delete",
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "delete",
    ]
  }

  lifecycle {
    ignore_changes = [access_policy]
  }

  tags = local.app_tags
}

resource "azurerm_key_vault_access_policy" "key_vault_access_policy_function_app" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_function_app.function_app.identity[0].principal_id

  key_permissions = [
    "get",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]
}

resource "azurerm_key_vault_secret" "key_vault_secret_basic_authentication_function" {
  name         = "BasicAuthenticationFunction"
  value        = base64encode(format("%s:%s", var.function_username, var.function_password))
  key_vault_id = azurerm_key_vault.key_vault.id
}


resource "azurerm_mysql_server" "mysql" {
  name                = "${local.domain}mysqlserver"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku_name = "B_Gen4_1"

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = var.mysql_server_login
  administrator_login_password = var.mysql_server_password
  version                      = var.mysql_server_version
  ssl_enforcement              = "Enabled"

  tags = local.app_tags
}


resource "azurerm_mysql_database" "mysql" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.resource_group.location
  server_name         = azurerm_mysql_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}


resource "azurerm_container_registry" "container_registry" {
  name                     = "${local.domain}ContainerRegistry"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  sku                      = "Basic"
  admin_enabled            = true

  tags = local.app_tags
}

resource "azurerm_container_group" "container_group" {
  name                = "${local.domain}ContainerGroup"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  ip_address_type     = "public"
  dns_name_label      = "${local.domain}ContainerGroup"
  os_type             = "linux"

  image_registry_credential {
    server = azurerm_container_registry.container_registry.login_server
    username = azurerm_container_registry.container_registry.admin_username
    password = azurerm_container_registry.container_registry.admin_password
  }

  container {
    name   = "hello-world"
    image  = "microsoft/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  tags = local.app_tags
}

resource "azurerm_app_service_plan" "app_service_plan_back" {
  name                = "${local.domain}AppServicePlanBackend"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = local.app_tags
}

resource "azurerm_app_service" "app_service" {
  name                = "${local.domain}AppService"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  app_service_plan_id = azurerm_app_service_plan.app_service_plan_back.id

  site_config {
    linux_fx_version = "NODE|10.14"
    always_on = "true"
  }

  tags = local.app_tags
}
