@description('Name of the Key Vault. Must be globally unique.')
param kvName string

@description('Location for the Key Vault. Defaults to resource group location.')
param location string = resourceGroup().location

@description('SKU tier for the Key Vault.')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Number of days to retain soft-deleted secrets (7–90).')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7

@description('Name of the VM — used as the secret name in Key Vault.')
param vmName string

@description('Password value to store as a secret in Key Vault.')
@secure()
param generatedPassword string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true      // Use Azure RBAC for access control (modern approach)
    enableSoftDelete: true             // Required by Azure — cannot be disabled
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true // Allows ARM/Bicep to read secrets during deployment
  }
}

// Store the VM password as a secret in the Key Vault
resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'pass-${vmName}'
  properties: {
    value: generatedPassword
  }
}

output kvId string = keyVault.id
output kvUri string = keyVault.properties.vaultUri
output kvName string = keyVault.name
