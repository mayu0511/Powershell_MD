######################################################################################################################
# KMS Activation  | DEVELOPED BY:: Mahendra Dwivedi
# Version 1.2 |  KMS Activation | Date:: 08-June-2026
#=====================================================================================================================

try {
Add-Type -Path "D:\CC_Scripts\Powershell_MD\Others\Selenium\lib\WebDriver.dll" -ErrorAction Stop
Write-Host "WebDriver loaded successfully"
}
catch {
Write-Host "Failed to load WebDriver.dll"
Write-Host $_.Exception.Message
exit 1
}

# Verify IE Driver exists

$IEDriverFolder = "D:\CC_Scripts\Powershell_MD\Others\Selenium\IE_Driver"
$IEDriverExe = Join-Path $IEDriverFolder "IEDriverServer.exe"

if (!(Test-Path $IEDriverExe)) {
Write-Host "ERROR: IEDriverServer.exe not found at $IEDriverExe"
exit 1
}

# Logging

$LogFolder = "C:\Temp"

if (!(Test-Path $LogFolder)) {
New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogFolder "KMS_Automation_$TimeStamp.log"

function Write-Log {
param(
[string]$Message
)


$Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') : $Message"

Write-Host $Entry
Add-Content -Path $LogFile -Value $Entry


}

$driver = $null

try {


Write-Log "Starting KMS automation"

# Create IE Driver
$ieService = [OpenQA.Selenium.IE.InternetExplorerDriverService]::CreateDefaultService($IEDriverFolder)

$ieOptions = New-Object OpenQA.Selenium.IE.InternetExplorerOptions
$ieOptions.IgnoreZoomLevel = $true
$ieOptions.IntroduceInstabilityByIgnoringProtectedModeSettings = $true

$driver = New-Object OpenQA.Selenium.IE.InternetExplorerDriver($ieService, $ieOptions)

Start-Sleep -Seconds 3

function Set-Key {

    param(
        [string]$Url,
        [string]$FieldName,
        [string]$KeyValue,
        [string]$KeyName
    )

    try {

        Write-Log "Processing $KeyName"

        $driver.Navigate().GoToUrl($Url)

        Start-Sleep -Seconds 3

        $field = $driver.FindElement(
            [OpenQA.Selenium.By]::Name($FieldName)
        )

        if ($null -eq $field) {
            throw "Field $FieldName not found"
        }

        $field.Clear()
        $field.SendKeys($KeyValue)

        $submitButton = $driver.FindElement(
            [OpenQA.Selenium.By]::CssSelector("input.submit")
        )

        if ($null -eq $submitButton) {
            throw "Submit button not found"
        }

        $submitButton.Click()

        Start-Sleep -Seconds 3

        Write-Log "$KeyName updated successfully"

        return $true
    }
    catch {

        Write-Log "$KeyName failed. Error: $($_.Exception.Message)"

        return $false
    }
}

$MasterKey1 = Set-Key `
    -Url "https://localhost:8081/OrgK1/1" `
    -FieldName "OrgK1" `
    -KeyValue "plat" `
    -KeyName "Master Key1"

$MasterKey2 = Set-Key `
    -Url "https://localhost:8081/OrgK2/1" `
    -FieldName "OrgK2" `
    -KeyValue "corecard" `
    -KeyName "Master Key2"

$Org2Key1 = Set-Key `
    -Url "https://localhost:8081/OrgK1/2" `
    -FieldName "OrgK1" `
    -KeyValue "plat" `
    -KeyName "Org2 Key1"

$Org2Key2 = Set-Key `
    -Url "https://localhost:8081/OrgK2/2" `
    -FieldName "OrgK2" `
    -KeyValue "corecard" `
    -KeyName "Org2 Key2"

if ($MasterKey1 -and $MasterKey2 -and $Org2Key1 -and $Org2Key2) {

    Write-Log "SUCCESS - All keys updated successfully"
    exit 0
}
else {

    Write-Log "FAILURE - One or more key updates failed"
    exit 1
}


}
catch {


Write-Log "Unhandled error: $($_.Exception.Message)"
exit 1


}
finally {

if ($driver) {

    try {
        $driver.Quit()
        $driver.Dispose()
    }
    catch {
    }
}

Write-Log "Automation completed"

}
