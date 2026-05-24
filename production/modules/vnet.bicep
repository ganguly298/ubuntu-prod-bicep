@description('Name of the VNet.')
param vnetName string

@description('Name of the subnet.')
param subnetName string

@description('Location for the VNet.')
param location string = resourceGroup().location

@description('Address prefix for the VNet.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the subnet.')
param subnetAddressPrefix string = '10.0.0.0/24'

@description('Resource ID of the Network Security Group to associate with the subnet.')
param nsgId string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          networkSecurityGroup: {
            id: nsgId
          }
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}


output subnetId string = vnet.properties.subnets[0].id
