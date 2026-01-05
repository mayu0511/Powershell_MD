Clear-Host
$Module ="All_Process_list"

$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
}

if (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer -ErrorAction SilentlyContinue){
    $manufacturer = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer).ToUpper()
	$manufacturer
    if ($manufacturer -eq 'AMAZON EC2') {
			$envdetais='AWS'
        Write-Output "Server is running on AWS."
    }elseif ($manufacturer -eq 'VMware, Inc.') {
			$envdetais='VMS'
        Write-Output "Server is running on VMS."
    } 
}




if ($envdetais -eq 'AWS') {
$ServerTypes = 'svc', 'iss', 'aut', 'tnp', 'awf', 'src', 'snk', 'bat'
#$ServerTypes = 'iss'
$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName
$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon
$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]
$EnvironmentStack
$ServerList = $NULL
ForEach($ServerType in $ServerTypes) {
$ServerType
    $ServerListDetails = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)
    $ServerList += ($ServerListDetails | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvironmentStack")[1] } } | Sort-Object -Property serial).Name
 
 }
 }elseif($envdetais -eq 'VMS')
{
$ServerList = $NULL
$ServerTypes = 'app', 'TNP','AUTH','wf'
	
			$envdetais='VMS'
			if($ThisServer -match 'qa')
			{
				if($ThisServer -match 'uatp')
				{
				$envserver='qauatp'
				$EnvironmentName='PATUAT Lower'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}elseif($ThisServer -notmatch 'uatp' -and $ThisServer -match 'uat' )
				{
				$envserver='qauat'
				$EnvironmentName='UAT Lower'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}elseif($ThisServer -match 'dev' )
				{
				$envserver='qadev'
				$EnvironmentName='DEV Lower'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}elseif($ThisServer -match 'ptr' )
				{
				$envserver='qaptr'
				$EnvironmentName='PTR Lower'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}elseif($ThisServer -match 'int' )
				{
				$envserver='qaint'
				$EnvironmentName='INT Lower'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}elseif($ThisServer -notmatch 'uatp' -and $ThisServer -notmatch 'uat' -and $ThisServer -notmatch 'dev' -and $ThisServer -notmatch 'ptr' -and $ThisServer -notmatch 'int' -and $ThisServer -notmatch 'FW' -and $ThisServer -notmatch 'mpod')
				{
				$envserver='qa'
				$EnvironmentName='QA Lower'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}
				
			}elseif($ThisServer -match 'perf')
			{
				$envserver='perf'
				$EnvironmentName='perf'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				
			}elseif($ThisServer -match 'prod')
			{
			if($ThisServer -match 'proddr')
			{
				$envserver='proddr'
				$EnvironmentName='prod(RIC)'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
			}else{
				$envserver='prod'
				$EnvironmentName='prod(SUW)'
				$Environmentpod='pod1'
				$Environmentattributon='cookie'
				}
			}
			#$Environmentattributon=''
			#$EnvironmentStack=''
			$domainNamefind = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
			$domainName=$domainNamefind.Name
			$domainName
			ForEach($ServerType in $ServerTypes) {
			#$ServerType
   
   
			$serverfilter="$envserver$ServerType"
			$searcher = New-Object System.DirectoryServices.DirectorySearcher($domainName)
			$searcher.Filter = "(&(objectCategory=computer)(name=$serverfilter*))"
			$searcher.PropertiesToLoad.Add("name") | Out-Null
			$ServerListDetails  = $searcher.FindAll() | ForEach-Object {
				
			$_.Properties["name"]
}
 $ServerList += $ServerListDetails
 #($ServerListDetails | Select-Object @{n = "Name"; e = { $_.Name } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$EnvsironmentStack")[1] } } | Sort-Object -Property serial).Name
 
 }



}
 

#$ServerList


$Outputreport = "<HTML><TITLE> Process Validation Report </TITLE>
                 <BODY background-color:peachpuff>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                 <H2>$($EnvironmentName.ToUpper()) -PROCESS COUNT</H2></font>
                 <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                 <TD><B>Process Nae</B></TD>
                   <TD><B>Process Count</B></TD>
                   
                   </TR>"


$OutputreportVarVal = ""
$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
$collectionVariable = New-Object System.Collections.ArrayList
$collectionVariable1 =$null



ForEach ($computername in $ServerList) {


$collectionVariable1 += Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Continue -HideComputerName -ScriptBlock{


$AppServer = (get-process DbbApp*, rundbb_*)

$NameCount = $AppServer | Group-object| Select Name, Count
foreach($ff in $NameCount)
{

<#$kk = $ff.Name.Replace("System.Diagnostics.Process","");
$kk=$kk.Replace('(','').Replace('(','').Replace(')','');
$collectionVariable.Add( $kk + ',' + $ff.Count+ ',' + $computername);#>
$collectionVariable1 += "|" + $ff.Name + ',' + $ff.Count




}
$collectionVariable1

}
}
#Clear-Variable parts
#$collectionVariable1

$parts = $collectionVariable1.Split("|")

For (($i = 1); $i -lt $parts.Count; $i++)
{
#$parts.GetType()
#$parts[0]
$CharArray = $parts[$i].Split(",")

$kk = $CharArray[0].Replace("System.Diagnostics.Process","");
$kk=$kk.Replace('(','').Replace('(','').Replace(')','');

$temp = New-Object System.Object
    $temp | Add-Member -MemberType NoteProperty -Name "Task" -Value $kk
    $temp | Add-Member -MemberType NoteProperty -Name "Count1" -Value $CharArray[1]
    
    $collectionVariable.Add($temp) | Out-Null

}
<#$collectionWithItems = New-Object System.Collections.ArrayList

Foreach($jj in $collectionVariable)
{

$CharArray =$jj.Split(",")
$CharArray[0]
$CharArray[1]

$temp = New-Object System.Object
    $temp | Add-Member -MemberType NoteProperty -Name "Task" -Value $CharArray[0]
    $temp | Add-Member -MemberType NoteProperty -Name "Count1" -Value $CharArray[1]
    
    $collectionWithItems.Add($temp) | Out-Null


}#>

#$collectionWithItems
$mm = $collectionVariable | Sort-Object -Property "Task" -Unique


$i=0
Foreach($pp in $mm)
{
 $addCount =0
 $processName = $pp.Task

 foreach($innerpp in $collectionVariable){

 if($pp.Task -eq $innerpp.Task)
 {
    $addCount +=$innerpp.Count1
    
 }

 }

  $mm[$i++].Count1 = $addCount

}


$mm

Foreach($oo in $mm){

$OutputreportVarVal += "<TR align=center>"
$OutputreportVarVal += "<TD>$($oo.Task)</TD>
                    <TD>$($oo.Count1)</TD>
                    
                                      
                   </TR>"
}

$Outputreport += $OutputreportVarVal + "</Table></BODY></HTML>" 

 

$Outputreport += "<HTML><TITLE> Process Validation Report </TITLE>
                 <BODY background-color:peachpuff>
                 <font color =""#4682B4"" face=""Microsoft Tai le"">
                 <H2>$($EnvironmentName.ToUpper()) - Current Running Processes</H2></font>
                 <Table border=1 cellpadding=0 cellspacing=0>
                 <TR bgcolor=gray align=center>
                 <TD><B>Server Name</B></TD>
                   <TD><B>Process Name</B></TD>
                   <TD><B>Proces ID</B></TD>
                   <TD><B>Start Time</B></TD>
                   </TR>"

$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
ForEach ($computername in $ServerList) {

$Outputreport += Invoke-Command -ComputerName $computername -SessionOption $option -ErrorAction Continue -HideComputerName -ScriptBlock{
$OutputreportVarVal = $NULL


$AppServer = @(get-process DbbApp*, rundbb_*)

#$AppServer

$computername = hostname

$eachapp = $Null
$runningprocess = $null


foreach ($eachapp in $AppServer){


$runningprocess = @($eachapp).name
$runningprocessID =@($eachapp).ID
$runningprocessTime =@($eachapp).Starttime


$OutputreportVarVal += "<TR align=center>"
$OutputreportVarVal += "<TD>$($computername)</TD>
                    <TD>$("$runningprocess")</TD>
                    <TD>$("$runningprocessID")</TD>
                    <TD>$("$runningprocessTime")</TD>
                                      
                   </TR>"





}
$OutputreportVarVal
}
 }


$Outputreport += "</Table></BODY></HTML>" 

 
# Save the HTML content to a file

$ReportFilelocation='C:\Temp'				  
if (!(Test-Path -Path $ReportFilelocation -PathType Container)) {
    New-Item -Path $ReportFilelocation -ItemType Directory | Out-Null
    Write-Host "Folder created: $ReportFilelocation"
} else {
    Write-Host "Folder already exists: $ReportFilelocation"
}	
$ReportFileNamePrefix = $Module +"_Validation_"
$ReportFile = "$ReportFilelocation\$ReportFileNamePrefix$(Get-Date -Format yyyy-MM-dd-hhmm).html"
$Outputreport | out-file "$ReportFile"
#if($host.Name -eq "Windows PowerShell ISE Host"){Invoke-Item $ReportFile}
$SMTPServer = "email-smtp.$($Region.ToLower()).amazonaws.com"
$SecretObject = Get-SECSecretValue -secretid "ses-smtp-$EnvironmentName-secret"
$SMTPUser = ($SecretObject.SecretString | ConvertFrom-Json).id
$SMTPPassword= ($SecretObject.SecretString | ConvertFrom-Json).ses_smtp_password_v4
$EmailSender = "$EnvironmentName-alerts@infra.marcus.com"
if($Environmentattributon -eq "jazz"){$EmailReceiver = "POD3ConfigTeam@corecard.com"}else{$EmailReceiver = "gowtham.sreeram@corecard.com"}
$SMTPPasswordSecure = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPasswordSecure)

if($collectionVariable1 -ne $null)
{$EmailSubject = "[$($Environmentattributon.ToUpper()) $($EnvironmentName.ToUpper())] -- [PROCESS CHECKING] -- [LIST]"

Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $SMTPCredential -UseSsl -From $EmailSender -To $EmailReceiver -Subject $EmailSubject -BodyAsHtml $OutputReport -Priority High
}
else{Write-host "Check the Process Coun"}

Write-Host "Sending Email Notification"
#Send-MailMessage -SmtpServer $SMTPServer -Port 587 -Credential $SMTPCredential -UseSsl -From $EmailSender -To $EmailReceiver -Subject $EmailSubject -BodyAsHtml $OutputReport -Priority High

Write-Host "Email Notification Sent"
Clear-Variable ServerList
 Clear-Variable ThisServer
Clear-Variable Region
Clear-Variable ShortRegion
Clear-Variable AWSVarialbes
Clear-Variable Environmentattributon
Clear-Variable EnvironmentStack
Clear-Variable EnvironmentName
Clear-Variable Environmentpod
Clear-Variable SMTPServer
Clear-Variable SecretObject
Clear-Variable SMTPUser
Clear-Variable SMTPPassword
Clear-Variable EmailSender
Clear-Variable EmailReceiver
Clear-Variable SMTPPasswordSecure
Clear-Variable SMTPCredential
Clear-Variable EmailSubject
Clear-Variable Result
Clear-Variable collectionVariable1
Clear-Variable envdetais