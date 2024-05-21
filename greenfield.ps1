# Justin Tucker - 2024-05-20
# SPDX-FileCopyrightText: Copyright © 2024, Justin Tucker
# https://github.com/jst327/azure-greenfield

# Connect to your Azure subscription
Connect-AzAccount

$subscriptionID = (Get-AzContext).Subscription.Id

$paramDate = Get-Date -Format "MM-dd-yyyy"

$paramTimeZone = (Get-TimeZone).Id

$paramMAIN = @{
    'location' = 'centralus'
    'prefix' = 'ABC'
    'subID' = $subscriptionID
    'vnetSpace' = '10.0.0.0/16'
    'MgmtSubnet' = '10.0.0.0/24'
    'IntSubnet' = '10.0.1.0/24'
    'GWSubnet' = '10.0.50.0/27'
    'virtualMachineCount' = 2
    'virtualMachineSize' = 'Standard_B2ms'
    'officeNet1' = '10.1.0.0/24'
    'officeNet2' = '10.2.0.0/24'
    'officePubIP' = '8.8.8.8'
}

$paramRG = @{
    'Name' = $paramDate+'_'+'HBS_Greenfield_RG_Deployment'
    'location' = $paramMAIN.location
    'GlobalResourceGroup' = $paramMAIN.prefix.ToUpper()+'-Global'
    'MgmtResourceGroup' = $paramMAIN.prefix.ToUpper()+'-Management'
    'IntResourceGroup' = $paramMAIN.prefix.ToUpper()+'-Internal'
    'TemplateFile' = '.\Modules\rg.bicep'
    'TemplateParameterObject' = $paramMAIN
    'Verbose' = $true
}

$paramVNET = @{
    'Name' = $paramDate+'_'+'HBS_Greenfield_VNET_Deployment'
    'location' = $paramMAIN.location
    'ResourceGroupName' = $paramMAIN.prefix.ToUpper()+'-Global'
    'vnetName' = $paramMAIN.prefix.ToUpper()+'-Global'
    'TemplateFile' = '.\Modules\vnet.bicep'
    'TemplateParameterObject' = $paramMAIN
    'Verbose' = $true
}

# Grabs the Public IP of the currently connected PC and adds it into a variable.
$publicip = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$paramObject = @{
    'sourceIP'  = $publicip
}
$paramDC = @{
    'Name' = $paramDate+'_'+'HBS_Greenfield_DC_Deployment'
    'location' = $paramMAIN.location
    'prefix' = $paramMAIN.prefix
    'ResourceGroupName' = $paramMAIN.prefix.ToUpper()+'-Management'
    'subID' = $paramMAIN.subID
    'TemplateFile' = '.\Modules\dc.bicep'
    'TemplateParameterObject' = $paramObject
    'TimeZone' = $paramTimeZone
    'virtualMachineCount' = $paramMAIN.virtualMachineCount
    'virtualMachineSize' = $paramMAIN.virtualMachineSize
    'Verbose' = $true
}

$paramVPN = @{
    'Name' = $paramDate+'_'+'HBS_Greenfield_VPN_Deployment'
    'location' = $paramMAIN.location
    'officeNet1' = $paramMAIN.officeNet1
    'officeNet2' = $paramMAIN.officeNet2
    'officePubIP' = $paramMAIN.officePubIP
    'prefix' = $paramMAIN.prefix
    'ResourceGroupName' = $paramMAIN.prefix.ToUpper()+'-Global'
    'subID' = $paramMAIN.subID
    'TemplateFile' = '.\Modules\vpn.bicep'
    'TemplateParameterObject' = $paramMAIN
    'Verbose' = $true
}

# Step 1 = Create initial resource groups
New-AzDeployment -Name $paramRG.Name @paramRG

# Step 2 = Create VNET Address Space and Subnets
New-AzResourceGroupDeployment -Name $paramVNET.Name @paramVNET

# Step 3 = Create Domain Controller VM
New-AzResourceGroupDeployment -Name $paramDC.Name @paramDC

# Step 4 = Create Local Gateway and Virtual Network Gateway
New-AzResourceGroupDeployment -Name $paramVPN.Name @paramVPN