param name string
param location string
param username string
@secure()
param password string
param subnetId string

var pipSuffix = uniqueString(resourceGroup().id, deployment().name)


resource nic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: '${name}-nic-${pipSuffix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}
resource publicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${name}-pip-${pipSuffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-25h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: name
      adminUsername: username
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
