using './main.bicep'

// Region for all resources in the deployment
param location = 'centralus'

// 3 or 4 letter company acronym for prefix
param prefix = 'ABC'

param subID = ''

// Resource Group Parameters
param GlobalResourceGroup = '${toUpper(prefix)}-Global'
param IntResourceGroup = '${toUpper(prefix)}-Internal'
param MgmtResourceGroup = '${toUpper(prefix)}-Management'

// Virtual Network Parameters
param vnetName = '${toUpper(prefix)}-Global'
param vnetSpace = '10.50.0.0/21'
param GWSubnet = '10.50.7.0/27'
param IntSubnet = '10.50.1.0/24'
param MgmtSubnet = '10.50.0.0/24'

// Virtual & Local Network Gateway Parameters
param officeNet = [
  '10.0.0.0/24'
  '10.0.1.0/24'
  '10.0.2.0/24'
]
param officePubIP = '1.1.1.1'
param sharedKey = ''

// Virtual Machine Parameters
param adminPassword = readEnvironmentVariable('ADMIN_PASSWORD')
param sourceIP = ''
param TimeZone = ''
param virtualMachineCount = 2
param virtualMachineSize = 'Standard_B2ms'
