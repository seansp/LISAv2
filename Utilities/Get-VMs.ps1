# Linux on Hyper-V and Azure Test Code, ver. 1.0.0
# Copyright (c) Microsoft Corporation

# Description: This script lists the VMs in the current subscription and lists our Tags and VMAges.
param 
( 
    [switch] $OnlyTests,
    [switch] $NoSecrets,
    [switch] $IncludeAge,
    $AzureSecretsFile,
    [ScriptBlock] $filterScriptBlock
)

#Load libraries
Get-ChildItem .\Libraries -Recurse | Where-Object { $_.FullName.EndsWith(".psm1") } | ForEach-Object { Import-Module $_.FullName -Force -Global }

if( $NoSecrets -eq $false )
{
    #Read secrets file and terminate if not present.
    if ($AzureSecretsFile)
    {
        $secretsFile = $AzureSecretsFile
    }
    elseif ($env:Azure_Secrets_File) 
    {
        $secretsFile = $env:Azure_Secrets_File
    }
    else 
    {
        LogMsg "-AzureSecretsFile and env:Azure_Secrets_File are empty. Exiting."
        exit 1
    }
    if ( Test-Path $secretsFile)
    {
        LogMsg "Secrets file found."
        .\Utilities\AddAzureRmAccountFromSecretsFile.ps1 -customSecretsFilePath $secretsFile
        $xmlSecrets = [xml](Get-Content $secretsFile)
    }
    else
    {
        LogMsg "Secrets file not found. Exiting."
        exit 1
    }
}
function Get-VMAgeFromDisk()
{
	param
	(
      [Parameter(Mandatory=$true)] $vm
    )
    $storageKind = "none"
    $ageDays = -1
    if( $vm.StorageProfile.OsDisk.Vhd.Uri )
    {
        $vhd = $vm.StorageProfile.OsDisk.Vhd.Uri
        $storageAccount = $vhd.Split("/")[2].Split(".")[0]
        $container = $vhd.Split("/")[3]
        $blob = $vhd.Split("/")[4]
    
        $storageKind = "blob"
        $blobStorageUsed = Get-AzureRmStorageAccount | where {  $($_.StorageAccountName -eq $storageAccount) -and $($_.Location -eq $vm.Location) }
        if( $blobStorageUsed )
        {
            Set-AzureRmCurrentStorageAccount -ResourceGroupName $blobStorageUsed.ResourceGroupName -Name $storageAccount > $null
            $blobDetails = Get-AzureStorageBlob -Container $container -Blob $blob -ErrorAction SilentlyContinue
            if( $blobDetails )
            {
                $copyCompletion = $blobDetails.ICloudBlob.CopyState.CompletionTime
                $age = $($(get-Date)-$copyCompletion.DateTime)
                $ageDays = $age.Days
            }
        }
    }
    else
    {
        $storageKind = "disk"
        $osdisk = Get-AzureRmDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name -ErrorAction SilentlyContinue
        if( $osdisk )
        {
            $age = $($(Get-Date) - $osDisk.TimeCreated)
            $ageDays = $($age.Days)
        }
    }
    $ageDays
}

#Get all VMs and enumerate thru them adding items to results list.
$allVMs = Get-AzureRmVM
$allRGs = Get-AzureRmResourceGroup

$results = @()

$vmIndex = 0

foreach ($vm in $allVMs) 
{
    $include = $false
    if( $OnlyTests -eq $true ) 
    {
        if( $vm.Tags.TestName ) 
        { 
            $include = $true 
        }
    } 
    else 
    {
        $include = $true
    }

    if( $include -eq $true ) 
    {
        $result = @{
            'VMName' = $vm.Name
            'VMSize' = $vm.HardwareProfile.VmSize
            'VMRegion' = $vm.Location
            'ResourceGroupName' = $vm.ResourceGroupName
            'vm' = $vmIndex
        }
        $results += $result
    }
}
$results = $results | Foreach-Object { [pscustomobject] $_ }
#Now add the resource group details.
foreach( $result in $results )
{
    $rg = $allRGs | Where ResourceGroupName -eq $result.ResourceGroupName
    $result | Add-Member BuildURL $rg.Tags.BuildURL
    $result | Add-Member BuildUser $rg.Tags.BuildUser
    $result | Add-Member TestName $rg.Tags.TestName
    $result | Add-Member CreationDate $rg.Tags.CreationDate

    if( $rg.Tags.CreationDate )
    { 
        $days = ([DateTime]::Now - $rg.Tags.CreationDate).Days
        $result | Add-Member RGAge $days
    }
    else {
        $result | Add-Member RGAge ""
    }
}

#Apply custom filter.
if( $filterScriptBlock )
{
    $results = $results | Where-Object $filterScriptBlock
} 

#Perform costly age check
if( $IncludeAge )
{
    $ageIndex = 0
    LogMsg "Collecting VM age from disk details for $($results.Length) machines."
    foreach( $result in $results )
    {
        $result | Add-Member VMAge (Get-VMAgeFromDisk $allVms[$result.vm])
        $ageIndex = $ageIndex + 1
    }
}
#trim out the vm index.
foreach( $result in $results )
{
    $result.PSObject.Properties.Remove('vm')
}
#output the table
$results | Format-Table 