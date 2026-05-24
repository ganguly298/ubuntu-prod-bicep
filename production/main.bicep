param name string    
param location string = resourceGroup().location
param username string
param vnetName string
param subnetName string
param vnetAddressPrefix string 
param subnetAddressPrefix string 
param kvName string = 'myKeyvault-296a'


var VMname = 'vm-${name}'
var generatedPassword = 'Pwd-${uniqueString(resourceGroup().id, deployment().name)}1!'

// 1. Deploy Key Vault and store the VM password secret
module kvModule './modules/keyvault.bicep' = {
  name: 'kv-deployment'
  params: {
    kvName: kvName
    location: location
    vmName: VMname
    generatedPassword: generatedPassword
  }
}

// 2. Reference existing KV to use getSecret() — required by Bicep; getSecret() cannot be a module output
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
}

// 3. Deploy NSG first so it can be attached to the subnet
module nsgModule './modules/nsg.bicep' = {
  name: 'nsg-deployment'
  params: {
    nsgName: '${subnetName}-nsg'
    location: location
  }
}

module vnetModule './modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    nsgId: nsgModule.outputs.nsgId
  }
}

// 4. VM reads password directly from Key Vault — not from the variable
module vmModule './modules/vm.bicep' = {
  name: 'vm-deployment'
  params: {
    name: VMname
    location: location
    username: username
    password: kv.getSecret('pass-${VMname}')
    subnetId: vnetModule.outputs.subnetId
  }
  dependsOn: [kvModule]
}