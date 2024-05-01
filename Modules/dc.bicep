param location string
param prefix string
param subID string
param sourceIP string
param networkInterfaceName string = '${toLower(prefix)}-ad-p0'
param networkSecurityGroupName string = '${toLower(prefix)}-ad-p0'
param networkSecurityGroupRules array = [
  {
    name: 'default-allow-rdp'
    properties: {
      priority: 1000
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: sourceIP
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  }
]
param subnetName string = 'Management'
param vnetId string = virtualNetworkId
param subnetRef string = '${vnetId}/subnets/${subnetName}'
param virtualNetworkId string = '/subscriptions/${subID}/resourceGroups/${toLower(prefix)}-Global/providers/Microsoft.Network/virtualNetworks/${toLower(prefix)}-Global'
param publicIpAddressName string = '${toLower(prefix)}-ad-p0'
param publicIpAddressType string = 'Static'
param publicIpAddressSku string = 'Standard'
param pipDeleteOption string = 'Delete'
param virtualMachineName string = '${toLower(prefix)}-ad-p0'
param virtualMachineComputerName string = '${toLower(prefix)}-ad-p0'
param virtualMachineCount int
param osDiskType string = 'Premium_LRS'
param osDiskDeleteOption string = 'Delete'
param dataDisks array = [
  {
    lun: 0
    createOption: 'attach'
    deleteOption: 'Delete'
    caching: 'None'
    writeAcceleratorEnabled: false
    id: null
    name: '${toLower(prefix)}-ad-p0'
    storageAccountType: null
    diskSizeGB: null
    diskEncryptionSet: null
  }
]
param dataDiskResources array = [
  {
    name: '${toLower(prefix)}-ad-p0'
    sku: 'Premium_LRS'
    properties: {
      diskSizeGB: 32
      creationData: {
        createOption: 'empty'
      }
    }
  }
]
param virtualMachineSize string
param nicDeleteOption string = 'Delete'
param adminUsername string = '${toLower(prefix)}admin'

@secure()
param adminPassword string

param patchMode string = 'AutomaticByPlatform'
param enableHotpatching bool = true
param rebootSetting string = 'IfRequired'
param securityType string = 'TrustedLaunch'
param secureBoot bool = true
param vTPM bool = true
param diagnosticsStorageAccountName string = '${toLower(prefix)}managementdiag'
param diagnosticsStorageAccountId string = 'Microsoft.Storage/storageAccounts/${toLower(prefix)}managementdiag'
param diagnosticsStorageAccountType string = 'Standard_LRS'
param diagnosticsStorageAccountKind string = 'Storage'
param availabilitySetName string = '${toLower(prefix)}-ad-p0'
param availabilitySetPlatformFaultDomainCount int = 3
param availabilitySetPlatformUpdateDomainCount int = 5

var diagnosticsExtensionName = 'Microsoft.Insights.VMDiagnosticsSettings'
var storageUri = environment().suffixes.storage

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = [for item in range(1, virtualMachineCount): {
  name: '${networkSecurityGroupName}${item}-nsg'
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}]

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' = [for item in range(1, virtualMachineCount): {
  name: '${publicIpAddressName}${item}'
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
  sku: {
    name: publicIpAddressSku
  }
}]

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = [for item in range(1, virtualMachineCount): {
  name: '${networkInterfaceName}${item}-ip'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', '${networkInterfaceName}${item}')
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', '${networkSecurityGroupName}${item}-nsg')
    }
  }
  dependsOn: [
    networkSecurityGroup
    publicIpAddress
  ]
}]

resource dataDiskResources_name 'Microsoft.Compute/disks@2023-10-02' = [for item in range(1,virtualMachineCount): {
    name: '${toLower(prefix)}-ad-p0${item}_DataDisk_ADDS'
    location: location
    properties: {
      diskSizeGB: 32
      creationData: {
        createOption: 'Empty'
      }
    }
    sku: {
      name: 'Premium_LRS'
    }
  }
]

@batchSize(1)
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = [for item in range(1, virtualMachineCount): {
  name: '${virtualMachineName}${item}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        name: '${toLower(prefix)}-ad-p0${item}_OsDisk'
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-hotpatch'
        version: 'latest'
      }
      dataDisks: [
        for i in dataDisks: {
          name: '${virtualMachineName}${item}_DataDisk_ADDS'
          lun: i.lun
          createOption: i.createOption
          caching: i.caching
          diskSizeGB: i.diskSizeGB
          managedDisk: {
            id: (i.id ?? ((i.name == null)
              ? null
              : resourceId('Microsoft.Compute/disks', '${virtualMachineName}${item}_DataDisk_ADDS')))
            storageAccountType: i.storageAccountType
          }
          deleteOption: i.deleteOption
          writeAcceleratorEnabled: i.writeAcceleratorEnabled
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/networkInterfaces', '${networkInterfaceName}${item}-ip')
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    osProfile: {
      computerName: '${virtualMachineComputerName}${item}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: enableHotpatching
          patchMode: patchMode
          automaticByPlatformSettings: {
            rebootSetting: rebootSetting
          }
        }
        timeZone: 'Central Standard Time'
      }
    }
    securityProfile: {
      securityType: securityType
      uefiSettings: {
        secureBootEnabled: secureBoot
        vTpmEnabled: vTPM
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'https://${diagnosticsStorageAccountName}.blob.${storageUri}'
      }
    }
    availabilitySet: {
      id: availabilitySet.id
    }
  }
  dependsOn: [
    dataDiskResources_name
    diagnosticsStorageAccount
  ]
}]

resource diagnosticsStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: diagnosticsStorageAccountName
  location: location
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
  kind: diagnosticsStorageAccountKind
  sku: {
    name: diagnosticsStorageAccountType
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-09-01' = {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: availabilitySetPlatformFaultDomainCount
    platformUpdateDomainCount: availabilitySetPlatformUpdateDomainCount
  }
  sku: {
    name: 'Aligned'
  }
}
