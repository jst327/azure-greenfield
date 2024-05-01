targetScope = 'subscription'

// Not declared in this bicep file but needed for script to execute
param prefix string
param subID string
param vnetSpace string
param MgmtSubnet string
param IntSubnet string
param GWSubnet string
param virtualMachineCount int
param virtualMachineSize string
param officeNet1 string
param officeNet2 string
param officePubIP string

// Parameters pulled from script
param location string
param GlobalResourceGroup string
param MgmtResourceGroup string
param IntResourceGroup string

// Creating Global, Management, and Internal resource groups
resource GlobalResourceGroup_resource 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: GlobalResourceGroup
  location: location
}

resource MgmtResourceGroup_resource 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: MgmtResourceGroup
  location: location
}

resource IntResourceGroup_resource 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: IntResourceGroup
  location: location
}
