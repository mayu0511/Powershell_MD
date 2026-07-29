######################################################################################################################
# KMS Servers Recovery Setting | Updated by : Mahendra Dwivedi
# Version 1.2 | Date:: 20-May-2026
#======================================================================================================================

Clear-Host

$Module = "KSM Recovery Setting"

$ServerTypes = 'kms'

$ThisServer = $env:COMPUTERNAME.ToLower()

# Detect Region
if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
}
elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}
else {
    Write-Host "Unable to determine AWS region from hostname." -ForegroundColor Red
    exit
}

# Get AWS Instance Details
$AWSVariables = aws ec2 describe-instances `
    --query "Reservations[*].Instances[*].{
        AvailabilityZone:Placement.AvailabilityZone,
        IpAddress:PrivateIpAddress,
        Type:InstanceType,
        Name:Tags[?Key=='Name']|[0].Value,
        Status:State.Name,
        Environment:Tags[?Key=='environment']|[0].Value,
        Stack:Tags[?Key=='stack']|[0].Value,
        Attribution:Tags[?Key=='attribution']|[0].Value,
        Pod:Tags[?Key=='pod']|[0].Value
    }" `
    --filters "Name=instance-state-name,Values=running" `
              "Name=tag:Name,Values=$ThisServer" `
    --region $Region | ConvertFrom-Json

# Flatten AWS result
$AWSVariables = $AWSVariables[0][0]

if (-not $AWSVariables) {
    Write-Host "AWS instance details not found." -ForegroundColor Red
    exit
}

# Safe variable assignment
$EnvironmentName        = ($AWSVariables.Environment  | ForEach-Object { $_.ToLower() })
$EnvironmentAttribution = ($AWSVariables.Attribution | ForEach-Object { $_.ToLower() })
$EnvironmentStack       = ($AWSVariables.Stack       | ForEach-Object { $_.ToLower() })

if ($EnvironmentStack) {
    $EnvironmentStack = $EnvironmentStack[0]
}

# Determine POD
if ([string]::IsNullOrWhiteSpace($AWSVariables.Pod)) {

    if ($EnvironmentAttribution -eq "jazz") {
        $EnvironmentPod = "jazz"
    }
    else {

        $S3BucketsList = aws s3 ls

        if ($S3BucketsList -match "corecard-pod2-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod2"
        }
        elseif ($S3BucketsList -match "corecard-pod4-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod4"
        }
        elseif ($S3BucketsList -match "corecard-pod5-$EnvironmentName-$Region-config-files") {
            $EnvironmentPod = "pod5"
        }
    }
}
else {
    $EnvironmentPod = $AWSVariables.Pod.ToLower()
}

# Final null protection
if ([string]::IsNullOrWhiteSpace($EnvironmentPod)) {
    $EnvironmentPod = "unknown"
}

Write-Host "`nEnvironment Details" -ForegroundColor Cyan
Write-Host "Environment : $EnvironmentName"
Write-Host "Attribution : $EnvironmentAttribution"
Write-Host "Stack       : $EnvironmentStack"
Write-Host "Pod         : $EnvironmentPod"

$AllResults = @()
$ServerTypeCounts = @{}

foreach ($ServerType in $ServerTypes) {

    Write-Host "`nServer Type: $ServerType" -ForegroundColor DarkYellow

    $ServerList = aws ec2 describe-instances `
        --query "Reservations[*].Instances[*].{
            Name:Tags[?Key=='Name']|[0].Value,
            Status:State.Name
        }" `
        --filters "Name=instance-state-name,Values=running" `
                  "Name=tag:Name,Values=*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*" `
        --region $Region | ConvertFrom-Json

    # Flatten results
    $ServerList = $ServerList | ForEach-Object { $_ }

    $ServerTypeCounts[$ServerType] = $ServerList.Count

    $Option = New-PSSessionOption `
        -ProxyAccessType NoProxyServer `
        -OpenTimeout 20000

    foreach ($Server in $ServerList) {

        $ServerName = $Server.Name

        if ([string]::IsNullOrWhiteSpace($ServerName)) {
            continue
        }

        Write-Host "Checking Server: $ServerName" -ForegroundColor Magenta

        try {

            $Result = Invoke-Command `
                -ComputerName $ServerName `
                -SessionOption $Option `
                -ErrorAction Stop `
                -ScriptBlock {

                $serviceName = "KMSService"

                # Configure failure actions
                sc.exe failure $serviceName reset=0 actions=restart/60000/restart/60000/restart/60000 | Out-Null

                Start-Sleep -Seconds 2

                # Query failure actions
                $FailureOutput = sc.exe qfailure $serviceName

                $ResetPeriod  = 0
                $FirstFailure = 0
                $SecondFailure = 0
                $ThirdFailure = 0

                foreach ($Line in $FailureOutput) {

                    if ($Line -match "RESET PERIOD.*:\s+(\d+)") {
                        $ResetPeriod = [int]$Matches[1]
                    }

                    if ($Line -match "RESTART -- Delay = (\d+) milliseconds") {

                        $Delay = [int]$Matches[1] / 60000

                        if ($FirstFailure -eq 0) {
                            $FirstFailure = $Delay
                        }
                        elseif ($SecondFailure -eq 0) {
                            $SecondFailure = $Delay
                        }
                        else {
                            $ThirdFailure = $Delay
                        }
                    }
                }

                if (
                    $ResetPeriod -eq 0 -and
                    $FirstFailure -eq 1 -and
                    $SecondFailure -eq 1 -and
                    $ThirdFailure -eq 1
                ) {

                    [PSCustomObject]@{
                        Server = $env:COMPUTERNAME
                        Status = "PASSED"
                    }
                }
                else {

                    [PSCustomObject]@{
                        Server = $env:COMPUTERNAME
                        Status = "FAILED"
                    }
                }
            }

            $AllResults += $Result

            Write-Host "$($Result.Server) : $($Result.Status)" -ForegroundColor Green
        }
        catch {

            Write-Host "Failed on $ServerName : $_" -ForegroundColor Red

            $AllResults += [PSCustomObject]@{
                Server = $ServerName
                Status = "ERROR"
            }
        }
    }
}

# Output Summary
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan

$AllResults | Format-Table -AutoSize