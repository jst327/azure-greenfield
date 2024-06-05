# Justin Tucker - 2024-06-05
# SPDX-FileCopyrightText: Copyright © 2024, Justin Tucker
# https://github.com/jst327/azure-greenfield

# Connect to your Azure subscription
Connect-AzAccount

# Pull subscription ID from Azure account
$subscriptionID = (Get-AzContext).Subscription.Id

$paramDate = Get-Date -Format "MM-dd-yyyy"
$paramName = $paramDate+'_'+'HBS_Greenfield_Deployment'

# Configure parameter for VMs to use local computer's time zone
$paramTimeZone = (Get-TimeZone).Id

# Grabs the Public IP of the currently connected PC and adds it into a variable.
$sourceIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

# Input to secure string for local admin password
$env:ADMIN_PASSWORD = Read-Host "Enter local admin password" -MaskInput

$paramBicep = (bicep build-params .\main.bicepparam --stdout | ConvertFrom-Json).parametersJson | ConvertFrom-Json

# Script to run the entire deployment; Use main.bicepparam to modify parameters
New-AzDeployment `
    -Location $paramBicep.parameters.location.value `
    -Name $paramName `
    -TemplateParameterFile ".\main.bicepparam" `
    -sourceIP $sourceIP `
    -subID $subscriptionID `
    -TimeZone $paramTimeZone `
    -Verbose

# Remove adminPass variable from session
$env:ADMIN_PASSWORD = ''

# Set all network interfaces to static IP address using their dynamic assigned IP address
$allNics = Get-AzNetworkInterface
foreach ($Nic in $allNics){
$Nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
Set-AzNetworkInterface -NetworkInterface $Nic
}