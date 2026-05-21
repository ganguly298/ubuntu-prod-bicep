using '../main.bicep'

param name = 'worker-02-vm'
param username = 'saurav'

param existingVnetName = 'JENKINS-VNET'  // Change to match your existing VNet
param existingSubnetName = 'default'     // Change to match your existing Subnet
