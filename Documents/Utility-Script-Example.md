#Example Usages
## Get-LisaV2ScriptStatistics.ps1
PS /Utilities> ./Get-LISAv2Statistics.ps1
```Powershell
TestCase                                                      Platform        Category            Area                                     Tags
-----------------------------------------------------------------------------------------------------------------------------------------------
STRESSTEST-VERIFY-RESTART-MAX-SRIOV-NICS                         Azure          Stress          stress                stress,boot,network,sriov
STRESSTEST-RELOAD-MODULES-UP                              Azure,HyperV             BVT          Stress                                   stress
STRESSTEST-SYSBENCH                                             HyperV          Stress          stress                                   stress
STRESSTEST-CHANGE-MTU-RELOAD-NETVSC                             HyperV          Stress          stress                                   stress
STRESSTEST-BOOT-VM-LARGE-MEMORY                                 HyperV          Stress          stress                                   stress
STRESSTEST-EventId-18602-Regression                             HyperV          Stress          stress                                   stress
...

===== Test Cases Number per platform =====

Azure only: 91
Hyper-V only: 82
Both platforms: 33
...

===== Tag Details =====

Name                           Value
----                           -----
nested                         15
core                           24
...
```
## Get-VMs.ps1
```Powershell
PS /> ./Utilities/Get-VMs.ps1 -OnlyTests -AzureSecretsFile "c:\mysecretfile.xml"
VMName    TestName         BuildURL                                         ResourceGroup          VMRegion   VMAge BuildUser                      VMSize
------    --------         --------                                         -------------          --------   ----- ---------                      ------
client-vm VERIFY-DEP       https://someurl.com/job/id/console               MYRESOURCEGROUP        westeurope     1 User Account                   Standard_DS15_v2
...

PS /> ./Utilities/Get-VMs.ps1 -NoSecrets                   
VMName    TestName         BuildURL                                         ResourceGroup          VMRegion   VMAge BuildUser                      VMSize
------    --------         --------                                         -------------          --------   ----- ---------                      ------
vm001                                                                       MYRESOURCeGROUP        westeurope    23 User Account                   Standard_DS15_v3
client-vm VERIFY-DEP       https://someurl.com/job/id/console               MYRESOURCEGROUP        westeurope     1 User Account                   Standard_DS15_v2
vm017                                                                       MYOtherRESOURCeGROUP   eastus2      103 User Account                   Standard_DS15_v2
...

PS /> ./Utilities/Get-VMs.ps1 -NoSecrets -filterScriptBlock {$_.VMSize -eq 'Standard_DS15_v3'}                   
VMName    TestName         BuildURL                                         ResourceGroup          VMRegion   VMAge BuildUser                      VMSize
------    --------         --------                                         -------------          --------   ----- ---------                      ------
vm001                                                                       MYRESOURCeGROUP        westeurope    23 User Account                   Standard_DS15_v3

```
## Support Contact

Contact LisaSupport@microsoft.com (Linux Integration Service Support), if you have technical issues.