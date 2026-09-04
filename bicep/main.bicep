// =============================================================================
//  NimbusGuard IaC scanning demo — Azure (Bicep)
//
//  ⚠️  DEMO ONLY. Deliberately misconfigured. NimbusGuard compiles this Bicep
//  with the real `bicep` CLI and evaluates the resulting resources against the
//  same control catalog it uses at runtime. Control IDs noted per resource.
// =============================================================================

param location string = 'eastus'

// ── NG-AZURE-STORAGE-001 — public blob access, HTTP allowed, public network ──
resource publicStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'acmepublicdemo'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: false
    minimumTlsVersion: 'TLS1_0'
    publicNetworkAccess: 'Enabled'
    allowSharedKeyAccess: true
  }
  tags: {
    environment: 'prod'
  }
}

// ── NG-AZURE-NET — inbound SSH (22) allowed from any source ──────────────────
resource openNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'acme-open-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh-from-anywhere'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
  tags: {
    environment: 'prod'
  }
}

// ── NG-AZURE-KEYVAULT — no purge protection, public network access ───────────
resource weakVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'acme-weak-kv'
  location: location
  properties: {
    tenantId: '00000000-0000-0000-0000-000000000000'
    sku: {
      family: 'A'
      name: 'standard'
    }
    enablePurgeProtection: false
    enableRbacAuthorization: false
    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 7
    accessPolicies: []
  }
  tags: {
    environment: 'prod'
  }
}

// ── PASS — hardened storage account ──────────────────────────────────────────
resource privateStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'acmeprivatedemo'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    allowSharedKeyAccess: false
  }
  tags: {
    environment: 'prod'
  }
}
