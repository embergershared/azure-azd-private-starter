targetScope = 'resourceGroup'

param name string
param location string = 'global'
param tags object = {}
param virtualNetworkId string

var keyVaultZoneName = 'privatelink.vaultcore.azure.net'
#disable-next-line no-hardcoded-env-urls
var blobZoneName = 'privatelink.blob.core.windows.net'
#disable-next-line no-hardcoded-env-urls
var fileZoneName = 'privatelink.file.core.windows.net'
resource keyVaultZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: keyVaultZoneName
  location: location
  tags: tags
}

resource blobZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: blobZoneName
  location: location
  tags: tags
}

resource fileZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: fileZoneName
  location: location
  tags: tags
}

resource keyVaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: keyVaultZone
  name: '${name}-kv-link'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource blobLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: blobZone
  name: '${name}-blob-link'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource fileLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: fileZone
  name: '${name}-file-link'
  location: location
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

output keyVaultZoneId string = keyVaultZone.id
output blobZoneId string = blobZone.id
output fileZoneId string = fileZone.id
