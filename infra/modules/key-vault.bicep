targetScope = 'resourceGroup'

@minLength(3)
@maxLength(24)
param name string
param location string = resourceGroup().location
param tags object = {}
@minLength(2)
@maxLength(80)
param privateEndpointName string
@minLength(2)
@maxLength(80)
param privateEndpointNetworkInterfaceName string
param privateEndpointSubnetId string
param privateDnsZoneId string
param logAnalyticsWorkspaceId string
param enableWindowsVm bool = false
param enableLinuxVm bool = false
param windowsAdminUsername string
@secure()
param windowsAdminPassword string = newGuid()
param linuxAdminUsername string
@secure()
param linuxAdminPassword string = newGuid()
param enableRoleAssignments bool = true
param operatorPrincipalIds array = []

var keyVaultSecretsUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource windowsUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = if (enableWindowsVm) {
  parent: keyVault
  name: 'windows-admin-username'
  tags: tags
  properties: {
    value: windowsAdminUsername
  }
}

resource windowsPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = if (enableWindowsVm) {
  parent: keyVault
  name: 'windows-admin-password'
  tags: tags
  properties: {
    value: windowsAdminPassword
  }
}

resource linuxUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = if (enableLinuxVm) {
  parent: keyVault
  name: 'linux-admin-username'
  tags: tags
  properties: {
    value: linuxAdminUsername
  }
}

resource linuxPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = if (enableLinuxVm) {
  parent: keyVault
  name: 'linux-admin-password'
  tags: tags
  properties: {
    value: linuxAdminPassword
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: privateEndpointNetworkInterfaceName
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'key-vault'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Approved by infrastructure deployment.'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'key-vault'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource secretReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in operatorPrincipalIds: if (enableRoleAssignments) {
    name: guid(keyVault.id, principalId, keyVaultSecretsUserRoleId)
    scope: keyVault
    properties: {
      principalId: principalId
      roleDefinitionId: keyVaultSecretsUserRoleId
    }
  }
]

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
