######################################################################################################################
# KMS Activation DEVELOPED BY: Mahendra Dwivedi
# Version 2.0  Date: 08-Jun-2026
######################################################################################################################

$ServerListFile = "D:\CC_Scripts\Servers.txt"
$ServerList = Get-Content $ServerListFile

foreach ($ComputerName in $ServerList)
{
Write-Host "Processing Server : $ComputerName" -ForegroundColor Cyan

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
Invoke-Command -ComputerName $ComputerName -SessionOption $option -ErrorAction inquire -ScriptBlock {
#Invoke-Command -ComputerName $ComputerName -ErrorAction Continue -ScriptBlock {

    $LogFolder = "C:\Temp"

    if (!(Test-Path $LogFolder))
    {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }

    $TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogFile = Join-Path $LogFolder "KMS_Activation_$TimeStamp.log"

    function Write-Log
    {
        param([string]$Message)

        $Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') : $Message"

        Write-Host $Entry
        Add-Content -Path $LogFile -Value $Entry
    }

    try
    {
        Write-Log "Starting KMS Activation"

        $Params = @{
            UseDefaultCredentials = $true
            UseBasicParsing       = $true
        }

        $BaseUrl = "https://localhost:8081"

        # Master Key1
        $r1 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK1/1" `
            -Method POST `
            -Body @{
                OrgK1  = "plat"
                OrgNum = "1"
            } `
            @Params

        Write-Log "Master Key1 Status Code : $($r1.StatusCode)"

        # Master Key2
        $r2 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK2/1" `
            -Method POST `
            -Body @{
                OrgK2  = "corecard"
                OrgNum = "1"
            } `
            @Params

        Write-Log "Master Key2 Status Code : $($r2.StatusCode)"

        # Org2 Key1
        $r3 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK1/2" `
            -Method POST `
            -Body @{
                OrgK1  = "plat"
                OrgNum = "2"
            } `
            @Params

        Write-Log "Org2 Key1 Status Code : $($r3.StatusCode)"

        # Org2 Key2
        $r4 = Invoke-WebRequest `
            -Uri "$BaseUrl/OrgK2/2" `
            -Method POST `
            -Body @{
                OrgK2  = "corecard"
                OrgNum = "2"
            } `
            @Params

        Write-Log "Org2 Key2 Status Code : $($r4.StatusCode)"

        if (
            $r1.StatusCode -eq 200 -and
            $r2.StatusCode -eq 200 -and
            $r3.StatusCode -eq 200 -and
            $r4.StatusCode -eq 200
        )
        {
            Write-Log "SUCCESS - KMS Activation Completed Successfully"
        }
        else
        {
            Write-Log "FAILURE - One or More Requests Failed"
        }
    }
    catch
    {
        Write-Log "ERROR : $($_.Exception.Message)"
    }

    Write-Log "Script Completed"
}


}
