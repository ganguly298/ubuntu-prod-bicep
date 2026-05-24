using '../main.bicep'

param name = 'worker-09-vm'
param username = 'saurav'

param vnetName = 'JENKINS-VNET'
param subnetName = 'default'
param vnetAddressPrefix = '10.0.0.0/16'
param subnetAddressPrefix = '10.0.0.0/24'
