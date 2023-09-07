##Zachary Isom
#Obtains information about a customer's installation of TFE Replicated from Azure

param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the name of the subscription that your TFE installation resides within")]
    [string]$SubscriptionName,
    [Parameter(Mandatory = $true, HelpMessage = "The resource group that contains all of the TFE resources")]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true, HelpMessage = "The name of the VM Scale Set that manages your TFE VMs")]
    [string]$VMScaleSetName,
    [Parameter(Mandatory = $true, HelpMessage = "The name of the PostgreSQL server that's used by your TFE installation")]
    [string]$PostgreSQLServerName,
    [Parameter(Mandatory = $true, HelpMessage = "The name of the Storage Account that's used by your TFE installation.")]
    [string]$StorageAccountName,
    [Parameter(Mandatory = $false, HelpMessage = "The name of the Redis Cache that's used by your TFE installation. This only applies to Active/Active installations. Disregard providing a value if you do not have this type of installation")]
    [string]$RedisCacheName
)

#Creates a timestamp for log entries
function TimeStamp { return "$(Get-Date -Format G):" }

Write-Host "$(TimeStamp) Starting Script" -ForegroundColor Yellow -BackgroundColor Black

#Sets which subscription all of the following commands adheres to
$SubscriptionContext = Set-AzContext -Subscription $SubscriptionName

$VMSSDisks = Get-AzDisk -ResourceGroupName $ResourceGroupName
$VMSS = Get-AzVmss -ResourceGroupName $ResourceGroupName -VMScaleSetName $VMScaleSetName | Select-Object `
@{Name = "VMSSName"; Expression = { $_.Name } }, `
@{Name = "OrchestrationMode"; Expression = { $_.OrchestrationMode } }, `
@{Name = "CurrentCapacity"; Expression = { $_.Sku.Capacity } }, `
@{Name = "LinuxDistro"; Expression = { $_.VirtualMachineProfile.StorageProfile.ImageReference.Offer } }, `
@{Name = "LinuxDistroVersion"; Expression = { $_.VirtualMachineProfile.StorageProfile.ImageReference.Sku } }, `
@{Name = "VMSize"; Expression = { $_.Sku.Name } }, `
@{Name = "VMSizeTier"; Expression = { $_.Sku.Tier } }, `
@{Name = "VMDisk1Name"; Expression = { $VMSSDisks[0].Name } }, `
@{Name = "VMDisk1Size"; Expression = { $VMSSDisks[0].DiskSizeGB } }, `
@{Name = "VMDisk1MaxIOPS"; Expression = { $VMSSDisks[0].DiskIOPSReadWrite } }, `
@{Name = "VMDisk1MaxThroughput"; Expression = { $VMSSDisks[0].DiskMBpsReadWrite } }, `
@{Name = "VMDisk2Name"; Expression = { $VMSSDisks[1].Name } }, `
@{Name = "VMDisk2Size"; Expression = { $VMSSDisks[1].DiskSizeGB } }, `
@{Name = "VMDisk2MaxIOPS"; Expression = { $VMSSDisks[1].DiskIOPSReadWrite } }, `
@{Name = "VMDisk2MaxThroughput"; Expression = { $VMSSDisks[1].DiskMBpsReadWrite } }, `
@{Name = "VMDisk3Name"; Expression = { $VMSSDisks[2].Name } }, `
@{Name = "VMDisk3Size"; Expression = { $VMSSDisks[2].DiskSizeGB } }, `
@{Name = "VMDisk3MaxIOPS"; Expression = { $VMSSDisks[2].DiskIOPSReadWrite } }, `
@{Name = "VMDisk3MaxThroughput"; Expression = { $VMSSDisks[2].DiskMBpsReadWrite } }, `
@{Name = "VMDisk4Name"; Expression = { $VMSSDisks[3].Name } }, `
@{Name = "VMDisk4Size"; Expression = { $VMSSDisks[3].DiskSizeGB } }, `
@{Name = "VMDisk4MaxIOPS"; Expression = { $VMSSDisks[3].DiskIOPSReadWrite } }, `
@{Name = "VMDisk4MaxThroughput"; Expression = { $VMSSDisks[3].DiskMBpsReadWrite } }

$DBFlexible = Get-AzPostgreSqlFlexibleServer -ResourceGroupName $ResourceGroupName -Name $PostgreSQLServerName | Select-Object `
@{Name = "DBName"; Expression = { $_.Name } }, `
@{Name = "DBMajorVersion"; Expression = { [string]$_.Version } }, `
@{Name = "DBMinorVersion"; Expression = { $_.MinorVersion } }, `
@{Name = "DBSize"; Expression = { $_.SkuName } }, `
@{Name = "DBSizeTier"; Expression = { [string]$_.SkuTier } }, `
@{Name = "DBDiskSizeGB"; Expression = { $_.StorageSizeGb } }, `
@{Name = "DBHAMode"; Expression = { [string]$_.HighAvailabilityMode } }, `
@{Name = "DBGeoRedundancy"; Expression = { [string]$_.BackupGeoRedundantBackup } }, `
@{Name = "DBBackupRetentionPeriod"; Expression = { $_.BackupRetentionDay } }

#If a Flexible Server is not found to exist, this will see if a Single server exists instead
if ($null -match $DBFlexible) {

    $DBSingle = Get-AzPostgreSqlServer -ResourceGroupName $ResourceGroupName -Name $PostgreSQLServerName | Select-Object `
    @{Name = "DBName"; Expression = { $_.Name } }, `
    @{Name = "DBMajorVersion"; Expression = { [string]$_.Version } }, `
    @{Name = "DBSize"; Expression = { $_.SkuName } }, `
    @{Name = "DBSizeTier"; Expression = { [string]$_.SkuTier } }, `
    @{Name = "DBDiskSizeMB"; Expression = { $_.StorageProfileStorageMb } }, `
    @{Name = "DBGeoRedundancy"; Expression = { [string]$_.StorageProfileGeoRedundantBackup } }, `
    @{Name = "DBBackupRetentionPeriod"; Expression = { $_.StorageProfileBackupRetentionDay } }

}

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$StorageAccountFileService = Get-AzStorageFileServiceProperty -StorageAccount $StorageAccount
$StorageAccount = Get-AzStorageBlobServiceProperty -StorageAccount $StorageAccount | Select-Object `
@{Name = "StorageAccountName"; Expression = { $StorageAccount.StorageAccountName } }, `
@{Name = "StorageAccountReplicationStrategy"; Expression = { $StorageAccount.Sku.Name } }, `
@{Name = "StorageAccountBlobVersioningEnabled"; Expression = { $_.IsVersioningEnabled } }, `
@{Name = "StorageAccountBlobSoftDeleteEnabled"; Expression = { $_.DeleteRetentionPolicy.Enabled } }, `
@{Name = "StorageAccountBlobSoftDeleteMaxDays"; Expression = { $_.DeleteRetentionPolicy.Days } }, `
@{Name = "StorageAccountContainerSoftDeleteEnabled"; Expression = { $_.ContainerDeleteRetentionPolicy.Enabled } }, `
@{Name = "StorageAccountContainerSoftDeleteMaxDays"; Expression = { $_.ContainerDeleteRetentionPolicy.Days } }, `
@{Name = "StorageAccountContainerRestoreEnabled"; Expression = { $_.RestorePolicy.Enabled } }, `
@{Name = "StorageAccountContainerRestoreMaxDays"; Expression = { $_.RestorePolicy.Days } }, `
@{Name = "StorageAccountFileSharesEnabled"; Expression = { $StorageAccountFileService.ShareDeleteRetentionPolicy.Enabled } }, `
@{Name = "StorageAccountFileSharesMaxDays"; Expression = { $StorageAccountFileService.ShareDeleteRetentionPolicy.Days } }

$CombinedObjectsArray = @($VMSS, $DBFlexible, $DBSingle, $StorageAccount)

if ($null -notmatch $RedisCacheName) {

    $RedisCache = Get-AzRedisCache -ResourceGroupName $ResourceGroupName -Name $RedisCacheName | Select-Object `
    @{Name = "RedisCacheName"; Expression = { $_.Name } }, `
    @{Name = "RedisCacheVersion"; Expression = { [string]$_.RedisVersion } }, `
    @{Name = "RedisCacheType"; Expression = { [string]$_.Sku } }


    $CombinedObjectsArray = @($VMSS, $DBFlexible, $DBSingle, $RedisCache, $StorageAccount)
}

$CombinedObjectsJson = $CombinedObjectsArray | ConvertTo-Json

# Save the JSON to a file
Set-Content -Path "$($PWD.path)\CombinedResults.json" -Value $CombinedObjectsJson

Write-Host "$(TimeStamp) Script execution complete. If no errors were encountered that need to be addressed, please upload $($PWD.path)\CombinedResults.json into your support ticket." -ForegroundColor Green -BackgroundColor Black