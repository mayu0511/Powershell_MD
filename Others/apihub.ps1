Clear-Host
$Module = "Web-NetworkManagementWebAPI"
$ServerType = 'apihub'

# Step 1: Get EC2 Metadata (Region + Instance ID)
try {
    $token = Invoke-RestMethod -Method PUT -Uri http://169.254.169.254/latest/api/token `
        -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }

    $identity = Invoke-RestMethod -Uri http://169.254.169.254/latest/dynamic/instance-identity/document `
        -Headers @{ "X-aws-ec2-metadata-token" = $token }

    $Region = $identity.region
    $InstanceId = $identity.instanceId
} catch {
    Write-Host "❌ ERROR: Could not fetch EC2 metadata." -ForegroundColor Red
    exit
}

# Step 2: Map Region to ShortRegion
$ShortRegion = switch ($Region) {
    "us-east-1" { "e1" }
    "us-west-2" { "w2" }
    default     { "xx" }
}

Write-Host "✅ Region: $Region"
Write-Host "✅ Instance ID: $InstanceId"
Write-Host "✅ ShortRegion: $ShortRegion"

# Step 3: Describe this instance and extract tags
try {
    $AWSVariables = aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --region $Region `
        --query "Reservations[*].Instances[*].{
            InstanceId:InstanceId,
            Name:Tags[?Key=='Name']|[0].Value,
            Environment:Tags[?Key=='environment']|[0].Value,
            Stack:Tags[?Key=='stack']|[0].Value,
            Attribution:Tags[?Key=='attribution']|[0].Value,
            Pod:Tags[?Key=='pod']|[0].Value,
            Status:State.Name,
            IpAddress:PrivateIpAddress
        }" | ConvertFrom-Json
} catch {
    Write-Host "❌ ERROR: Failed to describe instance $InstanceId." -ForegroundColor Red
    exit
}

$Instance = $AWSVariables[0][0]

# Extract metadata safely
$InstanceName       = $Instance.Name
$EnvironmentName    = if ($Instance.Environment) { $Instance.Environment.ToLower() } else { "qa" }
$EnvironmentStack   = if ($Instance.Stack)       { $Instance.Stack.ToLower() }       else { "" }
$EnvironmentAttrib  = if ($Instance.Attribution) { $Instance.Attribution.ToLower() } else { "" }
$EnvironmentPod     = if ($Instance.Pod)         { $Instance.Pod.ToLower() }         else { "" }

Write-Host "`n🌐 Environment: $EnvironmentName"
Write-Host "📦 Stack: $EnvironmentStack"
Write-Host "🏷️ Attribution: $EnvironmentAttrib"
Write-Host "📡 Pod: $EnvironmentPod"

# Step 4: Resolve Pod from S3 if needed
if (-not $EnvironmentPod) {
    $S3buckets = aws s3 ls

    if ($EnvironmentAttrib -eq "jazz") {
        $EnvironmentPod = "jazz"
    } elseif ($S3buckets -match "corecard-sharedservices-$EnvironmentName-$Region-config-files") {
        $EnvironmentPod = "pod2"
    } elseif ($S3buckets -match "corecard-pod5-$EnvironmentName-$Region-config-files") {
        $EnvironmentPod = "pod5"
    } else {
        $EnvironmentPod = "unknown"
    }
}

# Step 5: Create match pattern from Name
if ($InstanceName.Length -lt 8) {
    Write-Host "❌ ERROR: Name tag too short to extract pattern." -ForegroundColor Red
    exit
}
$MatchPrefix = $InstanceName.Substring(0, 8).ToLower()

Write-Host "`n🔍 Searching instances matching: $MatchPrefix*"

# Step 6: Describe all running instances and filter
try {
    $AllInstances = aws ec2 describe-instances `
        --region $Region `
        --filters "Name=instance-state-name,Values=running" `
        --query "Reservations[*].Instances[*].{
            InstanceId:InstanceId,
            Name:Tags[?Key=='Name']|[0].Value,
            PrivateIp:PrivateIpAddress,
            Status:State.Name
        }" | ConvertFrom-Json
} catch {
    Write-Host "❌ ERROR: Could not fetch instance list." -ForegroundColor Red
    exit
}

# Flatten
$FlatInstances = @()
foreach ($group in $AllInstances) { $FlatInstances += $group }

# Filter
$MatchingInstances = $FlatInstances | Where-Object {
    $_.Name -and $_.Name.ToLower().StartsWith($MatchPrefix)
}

# Output
if ($MatchingInstances.Count -eq 0) {
    Write-Host "`n❗ No matching instances found for: $MatchPrefix*" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Matched Instances:`n"
    $MatchingInstances | Select-Object InstanceId, Name, PrivateIp, Status | Format-Table -AutoSize
}
