param location string = resourceGroup().location
param prefix string
param networkInterfaceName string = '${toLower(prefix)}-ad-p0'
param networkSecurityGroupName string = '${toLower(prefix)}-ad-p0'
param pipDeleteOption string = 'Delete'
param subID string
param subnetName string = 'Management'
param virtualMachineCount int
param vnetId string = virtualNetworkId
param virtualNetworkId string = '/subscriptions/${subID}/resourceGroups/${toLower(prefix)}-Global/providers/Microsoft.Network/virtualNetworks/${toLower(prefix)}-Global'
param subnetRef string = '${vnetId}/subnets/${subnetName}'

@description('Private IP address')
param privateIpAddress string = ''

param privateIPAllocationMethod string = 'dynamic'

@description('Object containing resource tags.')
param tags object = {}

resource nicDeploy 'Microsoft.Network/networkInterfaces@2023-11-01' = [for i in range(1,virtualMachineCount): {
  name: '${networkInterfaceName}${i}-ip'
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: privateIPAllocationMethod
          privateIPAddress: (privateIPAllocationMethod == 'Dynamic') ? null: privateIpAddress
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', '${networkInterfaceName}${i}')
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${networkSecurityGroupName}${i}-nsg')
    }
  }
}]

//output nicId string = nicDeploy.id
//output nicName string = nicDeploy.name
output ipAddress string = nicDeploy.properties.ipConfigurations[0].properties.privateIPAddress

//output ipAddress string = privateIpAddress

resource nicDeploy2 'Microsoft.Network/networkInterfaces@2023-11-01' existing = {
  name: resourceId(nicDeploy.name)
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIpAddress
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', '${nicDeploy.name}')
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${networkSecurityGroupName}-nsg')
    }
  }
}
