param location string
param prefix string
param suffix string
param subID string
param sourceIP string
param networkInterfaceName string = '${toLower(prefix)}-ad-p${suffix}-ip'
param networkSecurityGroupName string = '${toLower(prefix)}-ad-p${suffix}-nsg'
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
param publicIpAddressName string = '${toLower(prefix)}-ad-p${suffix}'
param publicIpAddressType string = 'Static'
param publicIpAddressSku string = 'Standard'
param pipDeleteOption string = 'Delete'
param virtualMachineName string = '${toLower(prefix)}-ad-p${suffix}'
param virtualMachineComputerName string = '${toLower(prefix)}-ad-p${suffix}'
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
    name: '${toLower(prefix)}-ad-p${suffix}_DataDisk_ADDS'
    storageAccountType: null
    diskSizeGB: null
    diskEncryptionSet: null
  }
]
param dataDiskResources array = [
  {
    name: '${toLower(prefix)}-ad-p${suffix}_DataDisk_ADDS'
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

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var diagnosticsExtensionName = 'Microsoft.Insights.VMDiagnosticsSettings'
var storageUri = environment().suffixes.storage

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
  sku: {
    name: publicIpAddressSku
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: networkInterfaceName
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
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroup
    publicIpAddress
  ]
}

resource dataDiskResources_name 'Microsoft.Compute/disks@2023-10-02' = [
  for item in dataDiskResources: {
    name: item.name
    location: location
    properties: item.properties
    sku: {
      name: item.sku
    }
  }
]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: virtualMachineName
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
        name: '${toLower(prefix)}-ad-p${suffix}_OsDisk'
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-hotpatch'
        version: 'latest'
      }
      dataDisks: [
        for item in dataDisks: {
          name: item.name
          lun: item.lun
          createOption: item.createOption
          caching: item.caching
          diskSizeGB: item.diskSizeGB
          managedDisk: {
            id: (item.id ?? ((item.name == null)
              ? null
              : resourceId('Microsoft.Compute/disks', item.name)))
            storageAccountType: item.storageAccountType
          }
          deleteOption: item.deleteOption
          writeAcceleratorEnabled: item.writeAcceleratorEnabled
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
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
      computerName: virtualMachineComputerName
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
}

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
