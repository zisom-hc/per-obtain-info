Use this script to automatically pull the information we desire to know about your companies Terraform Enterprise installation.

This script assumes that:

* All of the resources that your TFE installation uses resides within the same Subscription
* All of the resources that your TFE installation uses are managed through a single Resource Group
* Your Azure account has read access to these services:
  * VM Scale Sets
  * PostgreSQL Flexible and Single Servers
  * Redis Cache for Azure
  * Storage Accounts
 
Steps to Perform:

1. Create a copy of the script within your local workstation
2. Open a PowerShell terminal
3. `cd` to the directory where the copy of the script you created resides
4. Install the Azure PowerShell module within PowerShell, if you have not already using the instructions here: https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-10.2.0
5. Execute `Connect-AzAccount` to login to Azure within your terminal, if not done so already
6. Provide values for each of these parameters, then execute the command: `.\Obtain-info-azure.ps1 -SubscriptionName <> -ResourceGroupName <> -VMScaleSetName <> -PostgreSQLServerName <> -StorageAccountName <> -RedisCacheName <>`
   * Only include the `-RedisCacheName` parameter if your team has an Active/Active installation of TFE provisioned.
