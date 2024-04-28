param location string
param prefix string
param name string = '${toUpper(prefix)}-Office'
param officePubIP string
param gatewayIP string = officePubIP
param officeNet1 string
param officeNet2 string

// Not declared in this bicep file but needed for script to execute
param suffix string
param subID string
param vnetSpace string
param MgmtSubnet string
param IntSubnet string
param GWSubnet string
param vmSize string

resource symbolicname 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: name
  location: location
  properties: {
    gatewayIpAddress: gatewayIP
    localNetworkAddressSpace: {
      addressPrefixes: [
        officeNet1
        officeNet2
      ]
    }
  }
}
