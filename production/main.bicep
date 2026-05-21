param name string
param location string = resourceGroup().location
param username string
@secure()
param password string
param existingVnetName string
param existingSubnetName string


module vnetModule './modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    existingVnetName: existingVnetName
    existingSubnetName: existingSubnetName
  }
}

module vmModule './modules/vm.bicep' = {
  name: 'vm-deployment'
  params: {
    name: name
    location: location
    username: username
    password: password
    subnetId: vnetModule.outputs.subnetId
  }
}
