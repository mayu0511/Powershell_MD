Clear-Host
$Module = "Processes-Status"
$ServerTypes = 'bat'

$ThisServer = (hostname).ToLower()

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
} elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
} else {
    Write-Host "Unknown region for server: $ThisServer" -ForegroundColor Red
    exit
}

$AWSVariables = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value,Pod:Tags[?Key=='pod']|[0].Value}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" --region $Region | ConvertFrom-Json

if (-not $AWSVariables) {
    Write-Host "Failed to retrieve AWS instance data." -ForegroundColor Red
    exit
}

$EnvironmentName = $AWSVariables.Environment.ToLower()
$EnvironmentAttribution = $AWSVariables.Attribution.ToLower()
$EnvironmentStack = ($AWSVariables.Stack.ToLower())[0]

if (-not $AWSVariables.Pod) {
    $S3BucketsList = aws s3 ls
    if ($EnvironmentAttribution -eq "jazz") {
        $EnvironmentPod = "jazz"
    } elseif ($S3BucketsList -match "corecard-pod2-$EnvironmentName-$Region-config-files") {
        $EnvironmentPod = "pod2"
    } elseif ($S3BucketsList -match "corecard-pod4-$EnvironmentName-$Region-config-files") {
        $EnvironmentPod = "pod4"
    } elseif ($S3BucketsList -match "corecard-pod5-$EnvironmentName-$Region-config-files") {
        $EnvironmentPod = "pod5"
    } else {
        $EnvironmentPod = "Unknown"
    }
} else {
    $EnvironmentPod = $AWSVariables.Pod.ToLower()
}

Write-Host "Environment Pod: $EnvironmentPod" -ForegroundColor Cyan

# Collect results
$AllResults = @()
$ServerTypeCounts = @{}

foreach ($ServerType in $ServerTypes) {
    Write-Host "Checking Server Type: $ServerType" -ForegroundColor DarkYellow

    $ServerList = aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" --region $Region | ConvertFrom-Json
    
    $ServerTypeCounts[$ServerType] = $ServerList.Count
    
    $Option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
    
    foreach ($Server in $ServerList) {
        $ServerName = $Server.Name
        try {
            $CommandResult = Invoke-Command -ComputerName $ServerName -SessionOption $Option -ErrorAction Stop -ScriptBlock {
                $exePath = "C:\\Program Files (x86)\\VisualCron\\VisualCronService.exe"
                if (Test-Path $exePath) {
                    $version = (Get-Item $exePath).VersionInfo.FileVersion
                    Write-Output $version
                } else {
                    Write-Output "Not Found"
                }
            }
            $AllResults += [PSCustomObject]@{
                'ServerName' = $ServerName
                'Version' = $CommandResult
            }
        } catch {
            Write-Host "Error checking $ServerName $_" -ForegroundColor Red
        }
    }
}

# Save results to HTML in tabular format
$HtmlHeader = "<html><head><title>VisualCorn Version Report</title></head><body><h2>VisualCorn Version Report</h2><table border='1'><tr><th>Server Name</th><th>Version</th></tr>"
$HtmlBody = ""

foreach ($Result in $AllResults) {
    $HtmlBody += "<tr><td>$($Result.ServerName)</td><td>$($Result.Version)</td></tr>"
}

$HtmlFooter = "</table></body></html>"
$HtmlContent = $HtmlHeader + $HtmlBody + $HtmlFooter
$HtmlContent | Out-File "C:\\VCTest.html"

# Open in default browser
Start-Process "C:\\VCTest.html"
