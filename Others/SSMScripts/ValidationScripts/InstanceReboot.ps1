Clear-Host

$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution,Pod:Tags[?Key=='pod']|[0].Value,Status:State.pod}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack

$domain = ($Env:USERDNSDOMAIN.Split('-')[1] ).split('.')[0]

if($domain -eq "POD2"){$Environmentpod = "pod2"}
if($domain -eq "POD4"){$Environmentpod = "pod4"}
if($domain -eq "Jazz"){$Environmentpod = "pod3"}

$Environmentpod


$Report = @()
$ServersType = "*ccisse1patuatb*","*ccsvce1patuatb*","*ccaute1patuatb*","*cctnpe1patuatb*","*ccawfe1patuatb*","*ccsnke1patuatb*","*ccsrce1patuatb*","*ccbate1patuatb*"

ForEach ($ServerType in $ServersType) {
    $Getresult = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{IPAddress:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ServerType'" | ConvertFrom-Json).name

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer  
    $Result = Invoke-Command -ComputerName $Getresult -SessionOption $option -ErrorAction Continue -ScriptBlock{ 
        $currentTime = Get-Date
        $oneHourAgo = $currentTime.AddHours(-2)
        $Systeminfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $lastBootTime = $Systeminfo.LastBootUpTime 
        $ServerName = $Systeminfo.CSName  

        if ($lastBootTime -ge $oneHourAgo) {
            $obj = New-Object PSObject -property @{
                "Server Name" = $ServerName
                "Last Reboot Time" = $lastBootTime
            }
            Return $obj
        }
    }
    
    if ($Result -ne $null) {
        $Report += $Result
    }
}


if ($Report.Count -eq 0) {
    $Report += New-Object PSObject -property @{
        "Server Name" = "No server reboots in the last hour"
        "Last Reboot Time" = ""
    }
}

$OutputReport = $Report | ConvertTo-Html -Property "Server Name","Last Reboot Time" -As Table -PreContent "<html><head><style>
    table {
        font-family: Arial, sans-serif;
        border-collapse: collapse;
        width: 80%;
    }

    th, td {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
    }

    tr:nth-child(even) {
        background-color: #f2f2f2;
    }

    th {
        background-color: #FF0000;
        color: white;
    }
</style></head><body><h1>Server Reboot Report</h1><p><h3>Region: $region</h3></p><table>" -PostContent "</table></body></html>" | Out-String

$OutputReport | Set-Content -Path "D:/Report.html"

#Invoke-Item "D:/Report.html"
Write-Host $OutputReport

if($OutputReport -notmatch "No server reboots in the last hour"){
$SMTPServer = "email-smtp.$($Region.ToLower()).amazonaws.com"
$SecretObject = Get-SECSecretValue -secretid "ses-smtp-$EnvironmentName-secret"
$SMTPUser = ($SecretObject.SecretString | ConvertFrom-Json).id
$SMTPPassword= ($SecretObject.SecretString | ConvertFrom-Json).ses_smtp_password_v4
$EmailSender = "$Environmentpod-$EnvironmentName-alerts@infra.marcus.com"
if($Environmentattributon -eq "jazz")
{$EmailReceiver = "POD3ConfigTeam@corecard.com","PlatSD@corecard.com"}
else
{$EmailReceiver = "POD2ConfigTeam@corecard.com","PlatSD@corecard.com"}
$SMTPPasswordSecure = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPasswordSecure)
$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper()) - $($Environmentpod.ToUpper())] -- [Instance Reboot Status] -- [Failure]"
Write-Host "Sending Email Notification"
Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $SMTPCredential -UseSsl -From $EmailSender -To $EmailReceiver -Subject $EmailSubject -BodyAsHtml $OutputReport -Priority High
Write-Host "Email Notification Sent"

Clear-Variable SMTPServer
Clear-Variable SecretObject
Clear-Variable SMTPUser
Clear-Variable SMTPPassword
Clear-Variable EmailSender
Clear-Variable EmailReceiver
Clear-Variable SMTPPasswordSecure
Clear-Variable SMTPCredential
Clear-Variable EmailSubject

}
else
{Write-host "Instace are not rebooted in the last hour, Mail not sent"}



Clear-Variable report
Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable EnvironmentName
Clear-Variable Environmentpod
Clear-Variable Result
Clear-Variable domain