param name string    
param location string = resourceGroup().location
param username string
param existingVnetName string
param existingSubnetName string
param kvName string = 'myKeyvault-296a'


var VMname = 'vm-${name}'
var generatedPassword = 'Pwd-${uniqueString(resourceGroup().id, deployment().name)}1!'

// 1. Deploy Key Vault
module kvModule './modules/keyvault.bicep' = {
  name: 'kv-deployment'
  params: {
    kvName: kvName
    location: location
  }
}

// 2. Store generated password into Key Vault (secret name is per-VM to avoid overwriting)
resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: kv
  name: VMname
  properties: {
    value: generatedPassword
  }
  dependsOn: [kvModule]
}

// 3. Reference existing KV to use getSecret()
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
}

module vnetModule './modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    existingVnetName: existingVnetName
    existingSubnetName: existingSubnetName
  }
}

// 4. VM reads password directly from Key Vault — not from the variable
module vmModule './modules/vm.bicep' = {
  name: 'vm-deployment'
  params: {
    name: VMname
    location: location
    username: username
    password: kv.getSecret(VMname)
    subnetId: vnetModule.outputs.subnetId
  }
  dependsOn: [kvSecret]
}
