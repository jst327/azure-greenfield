# Azure Greenfield Deployment

## Summary

Provides the infrastructure needed in a "greenfield" deployment to build out one or more domain controllers as an extension of your current on-premises network. 

Deployment will consist of:
1. Three resource groups (Global, Management, and Internal).
2. A virtual network and three subnets (Management, Internal, and GatewaySubnet).
3. Virtual machine(s) that are ready for ADDS promotion into your existing environment.
4. A local and virtual network gateway to establish a IPsec VPN connection to your on-premises office.

The end result will create everything needed so that you can RDP into the Azure virtual machine(s) and promote them as domain controllers.

## Execution

Download files to your machine. Before running, open <b>greenfield.ps1</b> and edit parameters under <b>$paramMAIN</b> as needed. No other changes will be required for the deployment.

$paramMAIN parameters explained:

| Parameter           | Description                                                                   |
|---------------------|-------------------------------------------------------------------------------|
| location            | Specify the Azure region for your deployment.                                 |
| prefix              | Specify the 3-letter company acronym for your deployment.                     |
| vnetSpace           | Specify the network address for your virtual network.                         |
| MgmtSubnet          | Specify the network range for your Management subnet.                         |
| IntSubnet           | Specify the network range for your Internal subnet.                           |
| GWSubnet            | Specify the network range for your Gateway subnet. Must be /27 network.       |
| virtualMachineCount | Specify the number of virtual machines to be created.                         |
| virtualMachineSize  | Specify the instance size of the virtual machine(s).                          |
| officeNet1          | Specify the internal network of your office for the IPsec VPN connection.     |
| officeNet2          | Specify an additional internal network if necessary for IPsec VPN connection. |
| officePubIP         | Specify the public IP of your office for the IPsec VPN connection.            |

Once you are happy with your parameters, simply run the script in PowerShell or Visual Studio Code. This was created and tested using PowerShell 7.4.2. You can download Visual Studio Code [here](https://code.visualstudio.com/download) if you don't already have it installed.

For PowerShell:
1. Open PowerShell 7 as administrator.
2. Run cd commands to navigate to directory where the greenfield.ps1 and Modules folder are downloaded.
3. Run .\greenfield.ps1

## Post-Deployment

Once the deployment has completed, the VPN connection should be established between your Azure virtual network and on-premises network. You will need to configure your virtual machine(s) to have a static IP address and point DNS to your on-premises domain controller. Follow these steps to proceed:

1. In the Azure portal, go to virtual machines. For each virtual machine:
   1. Click on <b>Network settings</b>
   2. Click on the link under Network interface / IP configuration (e.g. <b>abc-ad-p01 (primary) / ipconfig1 (primary)</b>)
   3. Click on <b>ipconfig1</b>
   4. Select the <b>static</b> radio button under allocation.
   5. (Optional) Change the private IP address as needed.
   6. Click <b>save</b>
   7. Restart virtual machine(s) for changes to take effect
2. In the Azure portal, go to virtual networks.
   1. Click on the virtual network (e.g. <b>ABC-Global</b>)
   2. Click on <b>DNS servers</b>
   3. Select <b>Custom</b> radio button
   4. Add private IP addresses of on-premises DNS servers as needed
   5. Click <b>save</b>
   6. Restart virtual machine(s) for changes to take effect

The virtual machine(s) in Azure should be able to talk to your domain at this point. Join the virtual machine(s) to your domain and restart. Then, install the ADDS server role and promote them to a domain controller.   

## Dependencies

1. [PowerShell 7.4.2](https://learn.microsoft.com/en-us/powershell/) or later.
2. [Bicep 0.26.54](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) or later.

## Author

Justin Tucker<br>
https://www.linkedin.com/in/-tucker/