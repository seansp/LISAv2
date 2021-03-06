﻿# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the Apache License.
$result = ""
$currentTestResult = CreateTestResultObject
$resultArr = @()

$isDeployed = DeployVMS -setupType $currentTestData.setupType -Distro $Distro -xmlConfig $xmlConfig
if ($isDeployed) {
    try {
        $hs1VIP = $AllVMData.PublicIP
        $hs1vm1sshport = $AllVMData.SSHPort
        $hs1ServiceUrl = $AllVMData.URL
        $hs1vm1Dip = $AllVMData.InternalIP

        $OsImageSize = Get-AzureVMImage | where {$_.ImageName -eq $BaseOsImage} | % {$_.LogicalSizeInGB}
        $OsImageSizeByte = $OsImageSize*1024*1024*1024

        RemoteCopy -uploadTo $hs1VIP -port $hs1vm1sshport -files $currentTestData.files -username $user -password $password -upload
        RunLinuxCmd -username $user -password $password -ip $hs1VIP -port $hs1vm1sshport -command "chmod +x *" -runAsSudo

        LogMsg "Executing : $($currentTestData.testScript)"
        RunLinuxCmd -username $user -password $password -ip $hs1VIP -port $hs1vm1sshport -command "$python_cmd $($currentTestData.testScript) -e $OsImageSizeByte" -runAsSudo
        RunLinuxCmd -username $user -password $password -ip $hs1VIP -port $hs1vm1sshport -command "mv Runtime.log $($currentTestData.testScript).log" -runAsSudo
        RemoteCopy -download -downloadFrom $hs1VIP -files "/home/$user/state.txt, /home/$user/Summary.log, /home/$user/$($currentTestData.testScript).log" -downloadTo $LogDir -port $hs1vm1sshport -username $user -password $password
        $testResult = Get-Content $LogDir\Summary.log
        $testStatus = Get-Content $LogDir\state.txt
        LogMsg "Test result : $testResult"

        if ($testStatus -eq "TestCompleted") {
            LogMsg "Test Completed"
        }
    } catch {
        $ErrorMessage =  $_.Exception.Message
        $ErrorLine = $_.InvocationInfo.ScriptLineNumber
        LogMsg "EXCEPTION : $ErrorMessage at line: $ErrorLine"
    } finally {
        $metaData = ""
        if (!$testResult) {
            $testResult = "Aborted"
        }
        $resultArr += $testResult
    }   
} else {
    $testResult = "Aborted"
    $resultArr += $testResult
}

$currentTestResult.TestResult = GetFinalResultHeader -resultarr $resultArr

#Clean up the setup
DoTestCleanUp -currentTestResult $currentTestResult -testName $currentTestData.testName -deployedServices $isDeployed

#Return the result and summery to the test suite script..
return $currentTestResult
