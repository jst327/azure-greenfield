targetScope = 'subscription'

// Parameters pulled from greenfield.ps1 script
param location string
param GlobalResourceGroup string
param IntResourceGroup string
param MgmtResourceGroup string

// Creating Global, Management, and Internal resource groups
resource GlobalResourceGroup_resource 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: GlobalResourceGroup
  location: location
}

resource IntResourceGroup_resource 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: IntResourceGroup
  location: location
}

resource MgmtResourceGroup_resource 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: MgmtResourceGroup
  location: location
}
