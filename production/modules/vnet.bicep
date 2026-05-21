param existingVnetName string
param existingSubnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: existingVnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  parent: vnet
  name: existingSubnetName
}

output subnetId string = subnet.id
