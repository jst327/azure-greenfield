targetScope = 'subscription'

//Parameters not declared below but needed for script to run
param location string
param prefix string
param subID string

// Resource Group Parameters
param GlobalResourceGroup string
param IntResourceGroup string
param MgmtResourceGroup string

// Virtual Network Parameters
param vnetName string
param vnetSpace string
param GWSubnet string
param IntSubnet string
param MgmtSubnet string

// Virtual Machine Parameters
param sourceIP string
param TimeZone string
@secure()
param adminPassword string
param virtualMachineCount int
param virtualMachineSize string

// Virtual & Local Network Gateway Parameters
param officeNet array
param officePubIP string
param sharedKey string

module resourceGroup 'Modules/rg.bicep' = {
  name: 'resourceGroupDeploy'
  params: {
    location: location
    GlobalResourceGroup: GlobalResourceGroup 
    IntResourceGroup: IntResourceGroup
    MgmtResourceGroup: MgmtResourceGroup
  }
}

module virtualNetwork 'Modules/vnet.bicep' = {
  name: 'virtualNetworkDeploy'
  scope: az.resourceGroup(GlobalResourceGroup)
  params: {
    location: location
    GWSubnet: GWSubnet
    IntSubnet: IntSubnet
    MgmtSubnet: MgmtSubnet
    vnetName: vnetName
    vnetSpace: vnetSpace
  }
  dependsOn: [resourceGroup]
}

module virtualMachine 'Modules/dc.bicep' = {
  name: 'virtualMachineDeploy'
  scope: az.resourceGroup(MgmtResourceGroup)
  params: {
    location: location
    TimeZone: TimeZone
    prefix: prefix
    sourceIP: sourceIP
    subID: subID
    adminPassword: adminPassword
    virtualMachineCount: virtualMachineCount
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [resourceGroup]
}

module virtualGateway 'Modules/vpn.bicep' = {
  name: 'virtualGatewayDeploy'
  scope: az.resourceGroup(GlobalResourceGroup)
  params: {
    location: location
    officeNet: officeNet
    officePubIP: officePubIP
    prefix: prefix
    sharedKey: sharedKey
    subID: subID
  }
  dependsOn: [resourceGroup, virtualNetwork]
}
