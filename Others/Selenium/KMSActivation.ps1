# Load Selenium WebDriver
try {
    Add-Type -Path "D:\Backup\selenium.webdriver.3.141.0\lib\net35\WebDriver.dll" -ErrorAction Stop
    Write-Host "WebDriver loaded successfully"
}
catch {
    Write-Host "Failed to load WebDriver.dll"
    Write-Host $_.Exception.Message
    exit 1
}

# Verify IE Driver exists
$IEDriverFolder = "C:\Temp"
$IEDriverExe = Join-Path $IEDriverFolder "IEDriverServer.exe"

if (!(Test-Path $IEDriverExe)) {
    Write-Host "ERROR: IEDriverServer.exe not found at $IEDriverExe"
    exit 1
}

$driver = $null
$LogFile = "C:\Temp\AutomationLog.txt"

try {

    # Create IE Driver
    $ieService = [OpenQA.Selenium.IE.InternetExplorerDriverService]::CreateDefaultService($IEDriverFolder)

    $ieOptions = New-Object OpenQA.Selenium.IE.InternetExplorerOptions
    $ieOptions.IgnoreZoomLevel = $true
    $ieOptions.IntroduceInstabilityByIgnoringProtectedModeSettings = $true

    $driver = New-Object OpenQA.Selenium.IE.InternetExplorerDriver($ieService, $ieOptions)

    function Set-Key {

        param(
            [string]$Url,
            [string]$FieldName,
            [string]$KeyValue
        )

        Write-Host "Processing $Url"

        $driver.Navigate().GoToUrl($Url)

        Start-Sleep -Seconds 3

        $field = $driver.FindElement(
            [OpenQA.Selenium.By]::Name($FieldName)
        )

        $field.Clear()
        $field.SendKeys($KeyValue)

        $submitButton = $driver.FindElement(
            [OpenQA.Selenium.By]::CssSelector("input.submit")
        )

        $submitButton.Click()

        Start-Sleep -Seconds 3

        Write-Host "Completed $Url"

        return $true
    }

    # Master Key1
    $result1 = Set-Key `
        -Url "https://localhost:8081/OrgK1/1" `
        -FieldName "OrgK1" `
        -KeyValue "plat"

    # Master Key2
    $result2 = Set-Key `
        -Url "https://localhost:8081/OrgK2/1" `
        -FieldName "OrgK2" `
        -KeyValue "corecard"

    # Org2 Key1
    $result3 = Set-Key `
        -Url "https://localhost:8081/OrgK1/2" `
        -FieldName "OrgK1" `
        -KeyValue "plat"

    # Org2 Key2
    $result4 = Set-Key `
        -Url "https://localhost:8081/OrgK2/2" `
        -FieldName "OrgK2" `
        -KeyValue "corecard"

    if ($result1 -and $result2 -and $result3 -and $result4) {

        "SUCCESS: All keys updated successfully at $(Get-Date)" |
            Out-File $LogFile -Force

        Write-Host "SUCCESS: All keys updated"
    }
    else {

        "FAILURE: One or more key updates failed at $(Get-Date)" |
            Out-File $LogFile -Force

        Write-Host "FAILURE"
    }

}
catch {

    "ERROR: $($_.Exception.Message)" |
        Out-File $LogFile -Force

    Write-Host $_.Exception.Message
}
finally {

    if ($driver) {
        $driver.Quit()
        $driver.Dispose()
    }
}