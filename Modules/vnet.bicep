param location string
param vnetName string
param vnetSpace string
param MgmtSubnet string
param IntSubnet string
param GWSubnet string

// Not declared in this bicep file but needed for script to execute
param prefix string
param suffix string
param subID string
param vmSize string
param officeNet1 string
param officeNet2 string
param officePubIP string

param vnetSettings object = {
  name: vnetName
  location: location
  addressPrefixes: [
    {
      name: vnetName
      addressPrefix: vnetSpace
    }
  ]
  subnets: [
    {
      name: 'Management'
      addressPrefix: MgmtSubnet
    }
    {
      name: 'Internal'
      addressPrefix: IntSubnet
    }
    {
      name: 'GatewaySubnet'
      addressPrefix: GWSubnet
    }
  ]
}

// Creating VNET address space and subnets
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetSettings.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSettings.addressPrefixes[0].addressPrefix
      ]
    }
    subnets: [
      {
        name: vnetSettings.subnets[0].name
        properties: {
          addressPrefix: vnetSettings.subnets[0].addressPrefix
        }
      }
      {
        name: vnetSettings.subnets[1].name
        properties: {
          addressPrefix: vnetSettings.subnets[1].addressPrefix
        }
      }
      {
        name: vnetSettings.subnets[2].name
        properties: {
          addressPrefix: vnetSettings.subnets[2].addressPrefix
        }
      }
    ]
  }
}
