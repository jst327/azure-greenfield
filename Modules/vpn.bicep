param location string
param prefix string
param LGname string = '${toUpper(prefix)}-Office'
param VGname string = '${toUpper(prefix)}-Global-GW1'
param officeNet array
param officePubIP string
param gatewayType string = 'Vpn'
param subID string
param sku string = 'VpnGw1'
param vpnType string = 'RouteBased'
param vpnGatewayGeneration string = 'Generation1'
param subnetId string = '/subscriptions/${subID}/resourceGroups/${toUpper(prefix)}-Global/providers/Microsoft.Network/virtualNetworks/${toUpper(prefix)}-Global/subnets/GatewaySubnet'
param newPublicIpAddressName string = '${VGname}-IP1'
param connectionType string = 'IPsec'
param virtualNetworkGatewayId1 string = '/subscriptions/${subID}/resourceGroups/${toUpper(prefix)}-Global/providers/Microsoft.Network/virtualNetworkGateways/${VGname}'
param connectionName string = '${toUpper(prefix)}-Office'
param useLocalAzureIpAddress bool = false
param enableBgp bool = false
param connectionProtocol string = 'IKEv2'
param ipsecPolicies array = [
  {
    saLifeTimeSeconds: 27000
    saDataSizeKilobytes: 0
    ipsecEncryption: 'AES256'
    ipsecIntegrity: 'SHA256'
    ikeEncryption: 'AES256'
    ikeIntegrity: 'SHA256'
    dhGroup: 'ECP384'
    pfsGroup: 'None'
  }
]
param usePolicyBasedTrafficSelectors bool = false
param dpdTimeoutSeconds int = 45
param connectionMode string = 'Default'
param localNetworkGatewayId2 string = '/subscriptions/${subID}/resourceGroups/${toUpper(prefix)}-Global/providers/Microsoft.Network/localNetworkGateways/${LGname}'
param ingressNatRules array = []
param egressNatRules array = []
param sharedKey string

resource localgateway 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: LGname
  location: location
  properties: {
    gatewayIpAddress: officePubIP
    localNetworkAddressSpace: {
      addressPrefixes: officeNet
    }
  }
}

resource newPublicIpAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: newPublicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: []
}

resource vpngateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: VGname
  location: location
  tags: {}
  properties: {
    gatewayType: gatewayType
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: resourceId('${toUpper(prefix)}-Global', 'Microsoft.Network/publicIPAddresses', newPublicIpAddressName)
          }
        }
      }
    ]
    vpnType: vpnType
    vpnGatewayGeneration: vpnGatewayGeneration
    sku: {
      name: sku
      tier: sku
    }
  }
  dependsOn: [
    newPublicIpAddress, localgateway
  ]
}

resource connection 'Microsoft.Network/connections@2023-09-01' = {
  name: connectionName
  location: location
  tags: {}
  properties: {
    connectionType: connectionType
    virtualNetworkGateway1: {
      id: virtualNetworkGatewayId1
      properties: {
        
      }
    }
    useLocalAzureIpAddress: useLocalAzureIpAddress
    enableBgp: enableBgp
    connectionProtocol: connectionProtocol
    ipsecPolicies: ipsecPolicies
    usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors
    dpdTimeoutSeconds: dpdTimeoutSeconds
    connectionMode: connectionMode
    ingressNatRules: ingressNatRules
    egressNatRules: egressNatRules
    localNetworkGateway2: {
      id: localNetworkGatewayId2
      properties: {}
    }
    sharedKey: sharedKey
  }
  dependsOn: [
    localgateway, vpngateway
  ]
}
