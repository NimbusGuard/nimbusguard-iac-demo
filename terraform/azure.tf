# =============================================================================
#  NimbusGuard IaC scanning demo — Azure (Terraform)
#
#  ⚠️  DEMO ONLY. Deliberately misconfigured Azure resources so NimbusGuard's
#  scanner flags them at PR time. Control IDs noted per resource.
# =============================================================================

# ── NG-AZURE-KEYVAULT-002/003/004 — no purge protection, public, no RBAC ─────
resource "azurerm_key_vault" "app" {
  name                        = "acme-app-kv"
  location                    = "eastus"
  resource_group_name         = "acme-rg"
  tenant_id                   = "00000000-0000-0000-0000-000000000000"
  sku_name                    = "standard"
  purge_protection_enabled    = false
  public_network_access_enabled = true
  rbac_authorization_enabled  = false
  soft_delete_retention_days  = 7
  tags                        = { environment = "prod" }
}

# ── NG-AZURE-REDIS — non-SSL port on, public, TLS 1.0 ────────────────────────
resource "azurerm_redis_cache" "session" {
  name                          = "acme-session-cache"
  location                      = "eastus"
  resource_group_name           = "acme-rg"
  capacity                      = 1
  family                        = "C"
  sku_name                      = "Standard"
  non_ssl_port_enabled          = true
  public_network_access_enabled = true
  minimum_tls_version           = "1.0"
  tags                          = { environment = "prod" }
}

# ── NG-AZURE-ACR — admin user + anonymous pull + public network ──────────────
resource "azurerm_container_registry" "images" {
  name                          = "acmeimages"
  location                      = "eastus"
  resource_group_name           = "acme-rg"
  sku                           = "Premium"
  admin_enabled                 = true
  anonymous_pull_enabled        = true
  public_network_access_enabled = true
  tags                          = { environment = "prod" }
}

# ── NG-AZURE-COSMOSDB — public network, local auth (keys) enabled ────────────
resource "azurerm_cosmosdb_account" "catalog" {
  name                          = "acme-catalog"
  location                      = "eastus"
  resource_group_name           = "acme-rg"
  offer_type                    = "Standard"
  public_network_access_enabled = true
  local_authentication_enabled  = true
  tags                          = { environment = "prod" }
}

# ── NG-AZURE-POSTGRESQL — public flexible server ─────────────────────────────
resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "acme-pg"
  location                      = "eastus"
  resource_group_name           = "acme-rg"
  version                       = "15"
  public_network_access_enabled = true
  geo_redundant_backup_enabled  = false
  backup_retention_days         = 7
  tags                          = { environment = "prod" }
}

# =============================================================================
#  Hardened — these PASS.
# =============================================================================

# ── PASS — locked-down key vault ─────────────────────────────────────────────
resource "azurerm_key_vault" "secrets" {
  name                          = "acme-secrets-kv"
  location                      = "eastus"
  resource_group_name           = "acme-rg"
  tenant_id                     = "00000000-0000-0000-0000-000000000000"
  sku_name                      = "standard"
  purge_protection_enabled      = true
  public_network_access_enabled = false
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 90
  tags                          = { environment = "prod" }
}
