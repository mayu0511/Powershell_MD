Clear-Host
$ThisServer = (Hostname).ToLower()
if($ThisServer -match 'e1')
{$Region = "us-east-1"
$ShortRegion = 'e1'
} elseif($ThisServer -match 'w2')
{$Region = "us-west-2"
$ShortRegion = 'w2'
}

$AWSVarialbes = (aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Status:State.environment,Stack:Tags[?Key=='stack']|[0].Value,Status:State.stack,Attribution:Tags[?Key=='attribution']|[0].Value,Status:State.attribution}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json)

$EnvironmentName = $AWSVarialbes.Environment.ToLower()
$EnvironmentName

$Environmentattributon = $AWSVarialbes.Attribution.ToLower()
$Environmentattributon
$ProjectName = $Environmentattributon.ToUpper()

#$EnvironmentStack = ($AWSVarialbes.Stack.ToLower())[0]

$EnvironmentStack = $NULL

$AvailabilityZonesDefaultServerType = "tnp"
#$AZsComboBoxList = $NULL
#$AZsComboBoxList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Sort-Object  | Get-Unique

$CopyFileDirectory = "C:\CopyFiles"

if(Test-Path -Path $CopyFileDirectory){Remove-Item -Force -Path $CopyFileDirectory -Recurse}

if(Test-Path -Path $CopyFileDirectory){Write-Host "Unable to delete the folder, please remove manually and try again - " $CopyFileDirectory
Break Script}


#---------------------------------------------------------[Initialisations]--------------------------------------------------------
# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#$ExitTimeout = Start-Sleep -Seconds 10
#$ExitTimeout
#Read-Host "Wait"
#If ($ExitTimeout -eq "10"){break}




do{

$RunJob = $NULL



#---------------------------------------------------------[Form]--------------------------------------------------------

[System.Windows.Forms.Application]::EnableVisualStyles()

$ConfigOperationsForm                    = New-Object system.Windows.Forms.Form
$ConfigOperationsForm.ClientSize         = '500,500'
$ConfigOperationsForm.text               = "Config Operations"
$ConfigOperationsForm.BackColor          = "#ffffff"
$ConfigOperationsForm.TopMost            = $false
$ConfigOperationsForm.StartPosition      = 'CenterScreen'
#$Icon                                = New-Object system.drawing.icon ("C:\Users\utsav.tyagi\Downloads\Custom-Icon-Design-Mono-General-2-Document.ico")
#$ConfigOperationsForm.Icon               = $Icon

$Title                           = New-Object system.Windows.Forms.Label
$Title.text                      = "Config Operations"
$Title.AutoSize                  = $true
$Title.width                     = 25
$Title.height                    = 10
$Title.location                  = New-Object System.Drawing.Point(20,0)
$Title.Font                      = 'Microsoft Sans Serif,15'

$EnvironmentNameLabel            = New-Object system.Windows.Forms.Label
$EnvironmentNameLabel.text       = $EnvironmentName.ToUpper()
$EnvironmentNameLabel.AutoSize   = $true
$EnvironmentNameLabel.width      = 25
$EnvironmentNameLabel.height     = 10
$EnvironmentNameLabel.location   = New-Object System.Drawing.Point(320,0)
$EnvironmentNameLabel.Font       = 'Microsoft Sans Serif,15'


$ProjectLabel                     = New-Object System.Windows.Forms.Label
$ProjectLabel.text                = "$ProjectName"
$ProjectLabel.AutoSize            = $false
$ProjectLabel.width               = 100
$ProjectLabel.height              = 20
$ProjectLabel.location            = New-Object System.Drawing.Point(20,40)
$ProjectLabel.Font                = 'Microsoft Sans Serif,10'

$PODsComboBox                     = New-Object System.Windows.Forms.ComboBox
$PODsComboBox.text                = "Select POD"
$PODsComboBox.AutoSize            = $false
$PODsComboBox.width               = 150
$PODsComboBox.height              = 20
$PODsComboBox.location            = New-Object System.Drawing.Point(120,40)
$PODsComboBox.Font                = 'Microsoft Sans Serif,10'

$StacksComboBox                     = New-Object System.Windows.Forms.ComboBox
$StacksComboBox.text                = "Select Stack"
$StacksComboBox.AutoSize            = $false
$StacksComboBox.width               = 150
$StacksComboBox.height              = 20
$StacksComboBox.location            = New-Object System.Drawing.Point(320,40)
$StacksComboBox.Font                = 'Microsoft Sans Serif,10'

$OperationsComboBox                     = New-Object System.Windows.Forms.ComboBox
$OperationsComboBox.text                = "Select Operation"
$OperationsComboBox.AutoSize            = $false
$OperationsComboBox.width               = 450
$OperationsComboBox.height              = 20
$OperationsComboBox.location            = New-Object System.Drawing.Point(20,80)
$OperationsComboBox.Font                = 'Microsoft Sans Serif,10'


$JobsComboBox                     = New-Object System.Windows.Forms.ComboBox
$JobsComboBox.text                = "Select Job"
$JobsComboBox.AutoSize            = $false
$JobsComboBox.width               = 450
$JobsComboBox.height              = 20
$JobsComboBox.location            = New-Object System.Drawing.Point(20,120)
$JobsComboBox.Font                = 'Microsoft Sans Serif,10'

$ProcessTaskLabel                      = New-Object System.Windows.Forms.Label
$ProcessTaskLabel.text                = "Select Process/Task / Site"
$ProcessTaskLabel.AutoSize            = $false
$ProcessTaskLabel.width               = 150
$ProcessTaskLabel.height              = 40
$ProcessTaskLabel.location            = New-Object System.Drawing.Point(20,160)
$ProcessTaskLabel.Font                = 'Microsoft Sans Serif,10'


$ProcessTaskComboBox                     = New-Object System.Windows.Forms.CheckedListBox
$ProcessTaskComboBox.text                = "Select - Process Name / Task Name / Website"
$ProcessTaskComboBox.AutoSize            = $false
$ProcessTaskComboBox.width               = 300
$ProcessTaskComboBox.height              = 80
$ProcessTaskComboBox.location            = New-Object System.Drawing.Point(170,160)
$ProcessTaskComboBox.Font                = 'Microsoft Sans Serif,10'
$ProcessTaskComboBox.AllowDrop            = $True
$ProcessTaskComboBox.CheckOnClick           = $True
#$ProcessTaskComboBox.GetItemCheckState(0)           = $True
$ProcessTaskComboBox.HorizontalScrollbar          = $True
#$ProcessTaskComboBox.ScrollAlwaysVisible          = $True


$AZsLabel                      = New-Object System.Windows.Forms.Label
$AZsLabel.text                = "Select AZs"
$AZsLabel.AutoSize            = $false
$AZsLabel.width               = 150
$AZsLabel.height              = 20
$AZsLabel.location            = New-Object System.Drawing.Point(20,260)
$AZsLabel.Font                = 'Microsoft Sans Serif,10'



$AZsComboBox                     = New-Object System.Windows.Forms.CheckedListBox
$AZsComboBox.text                = "Select Availablity Zone"
$AZsComboBox.AutoSize            = $false
$AZsComboBox.width               = 300
$AZsComboBox.height              = 60
$AZsComboBox.location            = New-Object System.Drawing.Point(170,260)
$AZsComboBox.Font                = 'Microsoft Sans Serif,10'
$AZsComboBox.AllowDrop            = $True
$AZsComboBox.CheckOnClick           = $True


$ServerRangeLabel                      = New-Object System.Windows.Forms.Label
$ServerRangeLabel.text                = "Select Server Range"
$ServerRangeLabel.AutoSize            = $false
$ServerRangeLabel.width               = 200
$ServerRangeLabel.height              = 20
$ServerRangeLabel.location            = New-Object System.Drawing.Point(20,340)
$ServerRangeLabel.Font                = 'Microsoft Sans Serif,10'


$ServerRangeStartLabel                      = New-Object System.Windows.Forms.Label
$ServerRangeStartLabel.text                = "Start"
$ServerRangeStartLabel.AutoSize            = $false
$ServerRangeStartLabel.width               = 40
$ServerRangeStartLabel.height              = 20
$ServerRangeStartLabel.location            = New-Object System.Drawing.Point(260,340)
$ServerRangeStartLabel.Font                = 'Microsoft Sans Serif,10'


$ServerRangeStart                      = New-Object System.Windows.Forms.NumericUpDown
$ServerRangeStart.text                = "Select Server Range"
$ServerRangeStart.AutoSize            = $false
$ServerRangeStart.width               = 50
$ServerRangeStart.height              = 20
$ServerRangeStart.location            = New-Object System.Drawing.Point(300,340)
$ServerRangeStart.Font                = 'Microsoft Sans Serif,10'
$ServerRangeStart.Minimum              = 0
$ServerRangeStart.Maximum              = 999
#$ServerRangeStart.Enabled              = $false



$ServerRangeEndLabel                      = New-Object System.Windows.Forms.Label
$ServerRangeEndLabel.text                = "End"
$ServerRangeEndLabel.AutoSize            = $false
$ServerRangeEndLabel.width               = 40
$ServerRangeEndLabel.height              = 20
$ServerRangeEndLabel.location            = New-Object System.Drawing.Point(380,340)
$ServerRangeEndLabel.Font                = 'Microsoft Sans Serif,10'


$ServerRangeEnd                     = New-Object System.Windows.Forms.NumericUpDown
$ServerRangeEnd.text                = "Select Server Range"
$ServerRangeEnd.AutoSize            = $false
$ServerRangeEnd.width               = 50
$ServerRangeEnd.height              = 20
$ServerRangeEnd.location            = New-Object System.Drawing.Point(420,340)
$ServerRangeEnd.Font                = 'Microsoft Sans Serif,10'
$ServerRangeEnd.Minimum             = 0
$ServerRangeEnd.Maximum             = 999
#$ServerRangeEnd.Enabled              = $false


$ServerTypesLabel                      = New-Object System.Windows.Forms.Label
$ServerTypesLabel.text                = "Select Server Type"
$ServerTypesLabel.AutoSize            = $false
$ServerTypesLabel.width               = 150
$ServerTypesLabel.height              = 20
$ServerTypesLabel.location            = New-Object System.Drawing.Point(20,380)
$ServerTypesLabel.Font                = 'Microsoft Sans Serif,10'


$ServerTypesComboBox                     = New-Object System.Windows.Forms.CheckedListBox
$ServerTypesComboBox.text                = "Select Server Type"
$ServerTypesComboBox.AutoSize            = $false
$ServerTypesComboBox.width               = 300
$ServerTypesComboBox.height              = 60
$ServerTypesComboBox.location            = New-Object System.Drawing.Point(170,380)
$ServerTypesComboBox.Font                = 'Microsoft Sans Serif,10'
$ServerTypesComboBox.AllowDrop            = $True
$ServerTypesComboBox.CheckOnClick           = $True


if($Environmentattributon -eq "cookie"){
$PODsList = @("COOKIE-POD2", "COOKIE-POD4")}
else{$PODsList = @("POD3-JAZZ")}

$StackList = @("Blue", "Green", "None")

$OperationsList = @("Process Management", "Task Management", "IIS Management", "File Management" )

$ProcessesList = @("DbbAppServer*","Rundbb*","DbbAppServer_CoreAuth*", "DbbAppServer_CoreIssue*", "DbbAppServer_Services*", "Rundbb_AccountParametersUpdates*", "Rundbb_AccountReinstate*", "Rundbb_ACHBHubCreatePIIRequest*", "Rundbb_ACHBHubSendPIIRequest*", "Rundbb_ACHCreatePIIRequest*", "Rundbb_ACHSendPIIRequest*", "Rundbb_AlertNotification*", "Rundbb_BatchNotification", "Rundbb_BatchNotification2", "Rundbb_CBRBHubCreatePIIRequest*", "Rundbb_CBRBHubSendPIIRequest*", "Rundbb_CBRCreatePIIRequest*", "Rundbb_CBRSendPIIRequest*", "Rundbb_CoreAuthAging*", "Rundbb_CoreAuthManualAdminMessage*", "Rundbb_CoreAuthRetryAlert*", "Rundbb_CoreIssueRetryAlert*", "Rundbb_DBPD*", "Rundbb_ETNP*", "Rundbb_MCSink*", "Rundbb_MCSource*", "Rundbb_MergeAccounts*", "Rundbb_MSMQ*", "Rundbb_RetailAuthJobs*", "Rundbb_RewardAutoRedeem*", "Rundbb_Rewardnotification*", "Rundbb_TNP*", "Rundbb_UpdateCall*","Rundbb_APJob*","Rundbb_PendingTxn*","Rundbb_RewardPromoDetails*","Rundbb_APIQueue*","Rundbb_CBRManualDF*","Rundbb_BulkCardFileValidator*","Rundbb_BulkSOLDAPICall*")

$TasksList = @("Task_*","Task_DbbAppServer_CoreAuth*", "Task_DbbAppServer_CoreIssue*", "Task_DbbAppServer_Services*", "Task_AccountParametersUpdates*", "Task_AccountReinstate*", "Task_ACHBHubCreatePIIRequest*", "Task_ACHBHubSendPIIRequest*", "Task_ACHCreatePIIRequest*", "Task_ACHSendPIIRequest*", "Task_AlertNotification*", "Task_BatchNotification", "Task_BatchNotification2", "Task_CBRBHubCreatePIIRequest*", "Task_CBRBHubSendPIIRequest*", "Task_CBRCreatePIIRequest*", "Task_CBRSendPIIRequest*", "Task_CoreAuthAging*", "Task_CoreAuthManualAdminMessage*", "Task_CoreAuthRetryAlert*", "Task_CoreIssueRetryAlert*", "Task_DBPD*", "Task_ETNP*", "Task_MCSink*", "Task_MCSource*", "Task_MergeAccounts*", "Task_MSMQ*", "Task_RetailAuthJobs*", "Task_RewardAutoRedeem*", "Task_Rewardnotification*", "Task_TNP*", "Task_UpdateCall*", "Task_RewardPromoDetails*", "Task_PendingTxn*", "Task_APJob*" , "Task_RewardPromoDetails*", "Task_APIQueue*" , "Task_CBRManualDF*" , "Task_BulkCardFileValidator*" , "Task_BulkSOLDAPICall*" , "Amazon Ec2 Launch - Userdata Execution")

$WebSiteList = @("CoreIssue", "Services", "CoreCredit", "WCFServer", "WCF", "CoreCardServices")

$CopyList = @("APP_SETUP", "WCF_SETUP", "WEB_SETUP", "EWEB_SETUP", "KMS_SETUP")

#$AZsComboBoxList = @("us-east-1a", "us-east-1b","us-east-1c")

$ServerTypesComboBoxList = @("svc", "iss", "aut", "tnp", "awf", "src", "snk", "bat", "wcf", "web", "ew", "kms")

#Clear-Variable CopyFileDirectory

$Script:CopySourcePath = $NULL
$Script:CopySourcePathArchive = $NULL

foreach($POD in $PODsList){$PODsComboBox.Items.Add($POD)}

foreach($Stacks in $StackList){$StacksComboBox.Items.Add($Stacks)}

foreach($Operations in $OperationsList){$OperationsComboBox.Items.Add($Operations)}

#foreach($AZs in $AZsComboBoxList){$AZsComboBox.Items.Add($AZs)}

foreach($ServerTypes in $ServerTypesComboBoxList){$ServerTypesComboBox.Items.Add($ServerTypes)}

$PODsComboBox.Add_SelectedIndexChanged{
IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($StacksComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}

}

$StacksComboBox.Add_SelectedIndexChanged{
IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($StacksComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}
$AZsComboBox.Items.Clear()
$AZsComboBoxList = $NULL
#$StacksComboBox.SelectedItem.ToString().ToLower()[0]
If($StacksComboBox.SelectedItem.ToString() -eq "Blue"){$script:EnvironmentStack = "b"}
elseif($StacksComboBox.SelectedItem.ToString() -eq "Green"){$script:EnvironmentStack = "g"}
else{$script:EnvironmentStack = $NULL}
$script:EnvironmentStack
$AZsComboBoxList = ((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$script:EnvironmentStack*'" "Name=availability-zone,Values='*'" --region $Region | ConvertFrom-Json).AvailabilityZone) | Sort-Object | Get-Unique
$AZsComboBoxList | Out-Host
foreach($AZs in $AZsComboBoxList){$AZsComboBox.Items.Add($AZs)}

}


$OperationsComboBox.Add_SelectedIndexChanged{
$JobsComboBox.Items.Clear()
$ProcessTaskComboBox.Items.Clear()
#$AZsComboBox.Items.Clear()
#$ServerTypesComboBox.Items.Clear()
#[System.Windows.Forms.MessageBox]::Show($OperationsComboBox.SelectedItem.ToString() ) 

If($OperationsComboBox.SelectedItem.ToString() -eq "Process Management"){
$JobsList = @("Stop Processes", "Start Processes")
foreach($Jobs in $JobsList){$JobsComboBox.Items.Add($Jobs)}
#foreach($ProcessesTasks in $ProcessesList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}
#foreach($ServerTypes in $ServerTypesComboBoxList){$ServerTypesComboBox.Items.Add($ServerTypes)}
#foreach($AZs in $AZsComboBoxList){$AZsComboBox.Items.Add($AZs)}
}

elseif($OperationsComboBox.SelectedItem.ToString() -eq "Task Management"){
$JobsList = @("Disable Tasks", "Enable Tasks")
foreach($Jobs in $JobsList){$JobsComboBox.Items.Add($Jobs)}
#foreach($ProcessesTasks in $TasksList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}
#foreach($ServerTypes in $ServerTypesComboBoxList){$ServerTypesComboBox.Items.Add($ServerTypes)}
#foreach($AZs in $AZsComboBoxList){$AZsComboBox.Items.Add($AZs)}
}

elseif($OperationsComboBox.SelectedItem.ToString() -eq "IIS Management"){
$JobsList = @("Stop IIS", "Start IIS", "Reset IIS", "Stop and Disable W3SVC", "Enable and Start W3SVC", "Stop ScaleService", "Start ScaleService", "Recycle AppPool", "Set Connect As - ccgs-app-svc", "Set Connect As - ccgs-app-upg", "Set Connect As - ccgs-web-svc", "Set AppPool User - ccgs-app-svc", "Set AppPool User - ccgs-app-upg", "Set AppPool User - ccgs-web-svc", "Set X-Request-ID", "Disable IIS Logging", "Enable IIS Logging", "Set Worker Process 1", "Set Worker Process 4", "Set Worker Process 64", "Enable32bitApplication True", "Enable32bitApplication False", "IdleTimeoutAction Terminate", "IdleTimeoutAction Suspend")
foreach($Jobs in $JobsList){$JobsComboBox.Items.Add($Jobs)}
#foreach($ProcessesTasks in $TasksList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}
#foreach($ServerTypes in $ServerTypesComboBoxList){$ServerTypesComboBox.Items.Add($ServerTypes)}
#foreach($AZs in $AZsComboBoxList){$AZsComboBox.Items.Add($AZs)}
}
elseif($OperationsComboBox.SelectedItem.ToString() -eq "File Management"){
$JobsList = @("Copy APP_SETUP", "Copy WCF_SETUP", "Copy WEB_SETUP", "Copy EWEB_SETUP", "Copy KMS_SETUP")
foreach($Jobs in $JobsList){$JobsComboBox.Items.Add($Jobs)}
#foreach($ProcessesTasks in $TasksList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}
#foreach($ServerTypes in $ServerTypesComboBoxList){$ServerTypesComboBox.Items.Add($ServerTypes)}
#foreach($AZs in $AZsComboBoxList){$AZsComboBox.Items.Add($AZs)}
}


else{
$JobsComboBox.Items.Clear()
$JobsComboBox.text = "Select Job"


$ProcessTaskComboBox.Items.Clear()
$ProcessTaskComboBox.text = "Select - Process Name / Task Name"

#$AZsComboBox.Items.Clear()
#$AZsComboBox.text = "Select Availablity Zone"

#$ServerTypesComboBox.Items.Clear()
#$ServerTypesComboBox.text = "Select Server Type"
}

$JobsComboBox.text = "Select Job"
$ProcessTaskComboBox.text = "Select - Process Name / Task Name"
#$AZsComboBox.text                = "Select Availablity Zone"
#$ServerTypesComboBox.text = "Select Server Type"



$ServerRangeStart.Value                =0
$ServerRangeStart.Enabled              = $true
$ServerRangeEnd.Enabled              = $true
$ServerRangeEnd.Value              = 0
$SubmitButton.Enabled               = $false
}


$JobsComboBox.Add_SelectedIndexChanged{

$ProcessTaskComboBox.Items.Clear()
if($JobsComboBox.SelectedItem.ToString() -eq "Stop Processes"){
foreach($ProcessesTasks in $ProcessesList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}}

elseif($JobsComboBox.SelectedItem.ToString() -eq "Start Processes"){
foreach($ProcessesTasks in $TasksList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}
}
elseif(($JobsComboBox.SelectedItem.ToString() -eq "Disable Tasks") -or ($JobsComboBox.SelectedItem.ToString() -eq "Enable Tasks")){
foreach($ProcessesTasks in $TasksList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}}

elseif(($JobsComboBox.SelectedItem.ToString() -eq "Stop IIS") -or ($JobsComboBox.SelectedItem.ToString() -eq "Start IIS") -or ($JobsComboBox.SelectedItem.ToString() -eq "Reset IIS") -or ($JobsComboBox.SelectedItem.ToString() -eq "Stop and Disable W3SVC") -or ($JobsComboBox.SelectedItem.ToString() -eq "Enable and Start W3SVC")){
$ProcessTaskComboBox.Items.Add("IIS")}

elseif(($JobsComboBox.SelectedItem.ToString() -eq "Stop ScaleService") -or ($JobsComboBox.SelectedItem.ToString() -eq "Start ScaleService")){
$ProcessTaskComboBox.Items.Add("ScaleService")}

elseif(($JobsComboBox.SelectedItem.ToString() -eq "Recycle AppPool")  -or ($JobsComboBox.SelectedItem.ToString() -eq "Set Connect As - ccgs-app-svc") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set Connect As - ccgs-app-upg") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set Connect As - ccgs-web-svc") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set AppPool User - ccgs-app-svc") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set AppPool User - ccgs-app-upg") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set AppPool User - ccgs-web-svc") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set X-Request-ID") -or ($JobsComboBox.SelectedItem.ToString() -eq "Disable IIS Logging") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set Worker Process 1") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set Worker Process 4") -or ($JobsComboBox.SelectedItem.ToString() -eq "Set Worker Process 64")-or ($JobsComboBox.SelectedItem.ToString() -eq "Enable32bitApplication True")-or ($JobsComboBox.SelectedItem.ToString() -eq "Enable32bitApplication False")){
foreach($ProcessesTasks in $WebSiteList){$ProcessTaskComboBox.Items.Add($ProcessesTasks)}}

elseif(($JobsComboBox.SelectedItem.ToString() -eq "Copy APP_SETUP")){

$Script:CopySourcePath = join-path -path $CopyFileDirectory -childpath  $JobsComboBox.SelectedItem.ToString().Split(" ")[1]
$Script:CopySourcePathArchive = $Script:CopySourcePath + "_Archive"

#$Script:CopySourcePath = "$CopyFileDirectory\APP_SETUP"
#$Script:CopySourcePathArchive =  "$CopyFileDirectory\APP_SETUP_Archive"

if((Test-Path -Path $Script:CopySourcePath) -or (Test-Path -Path $Script:CopySourcePathArchive)){
$BothDirectoryPaths = "$Script:CopySourcePath\   OR   $Script:CopySourcePathArchive\"
$DeleteSourcePath = [System.Windows.MessageBox]::Show($BothDirectoryPaths,'Folders already exist, Do you want to delete it and recreate blank folders ?','YesNo','Question')
}

If($DeleteSourcePath  -eq "Yes"){
if(Test-Path -Path $Script:CopySourcePath){Remove-Item -Force -Path $Script:CopySourcePath -Recurse}
if(Test-Path -Path $Script:CopySourcePathArchive){Remove-Item -Force -Path $Script:CopySourcePathArchive -Recurse}

if(Test-Path -Path $Script:CopySourcePath){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePath
Break Script}
if(Test-Path -Path $Script:CopySourcePathArchive){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePathArchive
Break Script}
}

New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\DBBSetup\DSLs\CI\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\DBBSetup\DSLs\CoreAuth\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\DBBSetup\DSLs\Modularization\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\DBBSetup\BatchScripts\CoreAuth\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\DBBSetup\BatchScripts\CoreIssue\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\DBBSetup\ScaleFiles\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\CC_runtime\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\CC_Python\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\TraceFiles\CoreAuth\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP\TraceFiles\CoreIssue\"

New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\APP_SETUP_Archive\"

[System.Windows.MessageBox]::Show($Script:CopySourcePath,'Copy required files to below path, Press OK to open the folder','OK','Question')
Invoke-Item $Script:CopySourcePath
$ProcessTaskComboBox.Items.Add("Confirm Files Copied to Path ? - $Script:CopySourcePath")

}



elseif(($JobsComboBox.SelectedItem.ToString() -eq "Copy WCF_SETUP")){

$Script:CopySourcePath = join-path -path $CopyFileDirectory -childpath  $JobsComboBox.SelectedItem.ToString().Split(" ")[1]
$Script:CopySourcePathArchive = $Script:CopySourcePath + "_Archive"

#$Script:CopySourcePath = "$CopyFileDirectory\APP_SETUP"
#$Script:CopySourcePathArchive =  "$CopyFileDirectory\APP_SETUP_Archive"

if((Test-Path -Path $Script:CopySourcePath) -or (Test-Path -Path $Script:CopySourcePathArchive)){
$BothDirectoryPaths = "$Script:CopySourcePath\   OR   $Script:CopySourcePathArchive\"
$DeleteSourcePath = [System.Windows.MessageBox]::Show($BothDirectoryPaths,'Folders already exist, Do you want to delete it and recreate blank folders ?','YesNo','Question')
}

If($DeleteSourcePath  -eq "Yes"){
if(Test-Path -Path $Script:CopySourcePath){Remove-Item -Force -Path $Script:CopySourcePath -Recurse}
if(Test-Path -Path $Script:CopySourcePathArchive){Remove-Item -Force -Path $Script:CopySourcePathArchive -Recurse}

if(Test-Path -Path $Script:CopySourcePath){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePath
Break Script}
if(Test-Path -Path $Script:CopySourcePathArchive){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePathArchive
Break Script}
}


New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WCF_SETUP\WebServer\CoreCardServices\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WCF_SETUP\WebServer\WCF\"

New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WCF_SETUP_Archive\"

[System.Windows.MessageBox]::Show($Script:CopySourcePath,'Copy required files to below path, Press OK to open the folder','OK','Question')
Invoke-Item $Script:CopySourcePath
$ProcessTaskComboBox.Items.Add("Confirm Files Copied to Path ? - $Script:CopySourcePath")
}



elseif(($JobsComboBox.SelectedItem.ToString() -eq "Copy WEB_SETUP")){

$Script:CopySourcePath = join-path -path $CopyFileDirectory -childpath  $JobsComboBox.SelectedItem.ToString().Split(" ")[1]
$Script:CopySourcePathArchive = $Script:CopySourcePath + "_Archive"

#$Script:CopySourcePath = "$CopyFileDirectory\APP_SETUP"
#$Script:CopySourcePathArchive =  "$CopyFileDirectory\APP_SETUP_Archive"

if((Test-Path -Path $Script:CopySourcePath) -or (Test-Path -Path $Script:CopySourcePathArchive)){
$BothDirectoryPaths = "$Script:CopySourcePath\   OR   $Script:CopySourcePathArchive\"
$DeleteSourcePath = [System.Windows.MessageBox]::Show($BothDirectoryPaths,'Folders already exist, Do you want to delete it and recreate blank folders ?','YesNo','Question')
}

If($DeleteSourcePath  -eq "Yes"){
if(Test-Path -Path $Script:CopySourcePath){Remove-Item -Force -Path $Script:CopySourcePath -Recurse}
if(Test-Path -Path $Script:CopySourcePathArchive){Remove-Item -Force -Path $Script:CopySourcePathArchive -Recurse}

if(Test-Path -Path $Script:CopySourcePath){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePath
Break Script}
if(Test-Path -Path $Script:CopySourcePathArchive){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePathArchive
Break Script}
}


New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WEB_SETUP\WebServer\DBBScale\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WEB_SETUP\WebServer\ScaleService\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WEB_SETUP\WebServer\DBBWEB\"
New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WEB_SETUP\WebServer\Services\"

New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\WEB_SETUP_Archive\"

[System.Windows.MessageBox]::Show($Script:CopySourcePath,'Copy required files to below path, Press OK to open the folder','OK','Question')
Invoke-Item $Script:CopySourcePath
$ProcessTaskComboBox.Items.Add("Confirm Files Copied to Path ? - $Script:CopySourcePath")
}



elseif(($JobsComboBox.SelectedItem.ToString() -eq "Copy EWEB_SETUP")){

$Script:CopySourcePath = join-path -path $CopyFileDirectory -childpath  $JobsComboBox.SelectedItem.ToString().Split(" ")[1]
$Script:CopySourcePathArchive = $Script:CopySourcePath + "_Archive"

#$Script:CopySourcePath = "$CopyFileDirectory\APP_SETUP"
#$Script:CopySourcePathArchive =  "$CopyFileDirectory\APP_SETUP_Archive"

if((Test-Path -Path $Script:CopySourcePath) -or (Test-Path -Path $Script:CopySourcePathArchive)){
$BothDirectoryPaths = "$Script:CopySourcePath\   OR   $Script:CopySourcePathArchive\"
$DeleteSourcePath = [System.Windows.MessageBox]::Show($BothDirectoryPaths,'Folders already exist, Do you want to delete it and recreate blank folders ?','YesNo','Question')
}

If($DeleteSourcePath  -eq "Yes"){
if(Test-Path -Path $Script:CopySourcePath){Remove-Item -Force -Path $Script:CopySourcePath -Recurse}
if(Test-Path -Path $Script:CopySourcePathArchive){Remove-Item -Force -Path $Script:CopySourcePathArchive -Recurse}

if(Test-Path -Path $Script:CopySourcePath){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePath
Break Script}
if(Test-Path -Path $Script:CopySourcePathArchive){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePathArchive
Break Script}
}


New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\EWEB_SETUP\WebServer\CoreCredit\"

New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\EWEB_SETUP_Archive\"

[System.Windows.MessageBox]::Show($Script:CopySourcePath,'Copy required files to below path, Press OK to open the folder','OK','Question')
Invoke-Item $Script:CopySourcePath
$ProcessTaskComboBox.Items.Add("Confirm Files Copied to Path ? - $Script:CopySourcePath")
}



elseif(($JobsComboBox.SelectedItem.ToString() -eq "Copy KMS_SETUP")){

$Script:CopySourcePath = join-path -path $CopyFileDirectory -childpath  $JobsComboBox.SelectedItem.ToString().Split(" ")[1]
$Script:CopySourcePathArchive = $Script:CopySourcePath + "_Archive"

#$Script:CopySourcePath = "$CopyFileDirectory\APP_SETUP"
#$Script:CopySourcePathArchive =  "$CopyFileDirectory\APP_SETUP_Archive"

if((Test-Path -Path $Script:CopySourcePath) -or (Test-Path -Path $Script:CopySourcePathArchive)){
$BothDirectoryPaths = "$Script:CopySourcePath\   OR   $Script:CopySourcePathArchive\"
$DeleteSourcePath = [System.Windows.MessageBox]::Show($BothDirectoryPaths,'Folders already exist, Do you want to delete it and recreate blank folders ?','YesNo','Question')
}

If($DeleteSourcePath  -eq "Yes"){
if(Test-Path -Path $Script:CopySourcePath){Remove-Item -Force -Path $Script:CopySourcePath -Recurse}
if(Test-Path -Path $Script:CopySourcePathArchive){Remove-Item -Force -Path $Script:CopySourcePathArchive -Recurse}

if(Test-Path -Path $Script:CopySourcePath){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePath
Break Script}
if(Test-Path -Path $Script:CopySourcePathArchive){Write-Host "Folder Already exist please delete and try again - " $Script:CopySourcePathArchive
Break Script}
}


New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\KMS_SETUP\KMS\KMM\"

New-Item -ItemType Directory -Force -Path "$CopyFileDirectory\KMS_SETUP_Archive\"

[System.Windows.MessageBox]::Show($Script:CopySourcePath,'Copy required files to below path, Press OK to open the folder','OK','Question')
Invoke-Item $Script:CopySourcePath
$ProcessTaskComboBox.Items.Add("Confirm Files Copied to Path ? - $Script:CopySourcePath")
}


else{
$JobsComboBox.Items.Clear()
$JobsComboBox.text = "Select Job"


$ProcessTaskComboBox.Items.Clear()
$ProcessTaskComboBox.text = "Select - Process Name / Task Name"

$AZsComboBox.Items.Clear()
$AZsComboBox.text = "Select Availablity Zone"

$ServerTypesComboBox.Items.Clear()
$ServerTypesComboBox.text = "Select Server Type"


}

IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}

}




#$ProcessTaskComboBox.Add__ItemCheck{
#$ProcessTaskComboBox.SetItemChecked(1,'$true')
#If($ProcessTaskComboBox.GetItemCheckState(0).ToString() -eq "Checked"){
#$ProcessTaskComboBox.SetItemCheckState(1,"Checked")
#}}

$ProcessTaskComboBox.Add_SelectedIndexChanged{

IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}


#If($ProcessTaskComboBox.SelectedItem.ToString() -eq "APP SETUP"){

#Invoke-Item "D:\TEMP\"
#[System.Windows.MessageBox]::Show('Please copy files to and then Press OK "D:\TEMP\" ','COPY FILES','OK','Question')
#}

#If($ProcessTaskComboBox.GetItemCheckState($ProcessTaskComboBox.Items.IndexOf($ProcessTaskComboBox.SelectedItem.ToString())) -eq "Checked" ){
#$CopySourcePath = $NULL
#$CopySourcePath = join-path -path $CopyFileDirectory -childpath $ProcessTaskComboBox.SelectedItem.ToString()
#Invoke-Item $CopySourcePath
#[System.Windows.MessageBox]::Show($CopySourcePath,'Copy Files to below path and then Press OK','OK','Question')
#If($ProcessTaskComboBox.SelectedItem.ToString() -eq "Others"){
#$CopyOthersTargetPath = $NULL
#Add-Type -AssemblyName Microsoft.VisualBasic
#$CopyOthersTargetPath = [System.VisualBasic.Interaction]::InputBox('Please enter the target path and press ok', 'Target Path')
#$CopyOthersTargetPath
#Read-Host -Prompt "Target location" -AsSecureString
#}
#}

}


$AZsComboBox.Add_SelectedIndexChanged{

IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}

}



$ServerTypesComboBox.Add_SelectedIndexChanged{

IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}


}

$ServerRangeEnd.Add_ValueChanged{
IF(($PODsComboBox.SelectedIndex -ne "-1") -and ($JobsComboBox.SelectedIndex -ne "-1") -and ($ProcessTaskComboBox.SelectedIndex -ne "-1") -and ($AZsComboBox.SelectedIndex -ne "-1") -and ($ServerTypesComboBox.SelectedIndex -ne "-1") -and ($ServerRangeEnd.Value -ne "0"))
{$SubmitButton.Enabled  = $true}
else{$SubmitButton.Enabled = $false}

}

#$ServerRangeEnd.Add_ValueChanged{
#$ServerRangeEnd.Minimum = $ServerRangeStart.Value.ToString()}

#$ServerRangeStart.Add_ValueChanged{
#$ServerRangeStart.Maximum = $ServerRangeEnd.Value.ToString()}






$SubmitButton                       = New-Object system.Windows.Forms.Button
$SubmitButton.BackColor             = "#ffffff"
$SubmitButton.text                  = "Submit"
$SubmitButton.width                 = 90
$SubmitButton.height                = 30
$SubmitButton.location              = New-Object System.Drawing.Point(205,460)
$SubmitButton.Font                  = 'Microsoft Sans Serif,10'
$SubmitButton.ForeColor             = "#000"
$SubmitButton.Enabled               = $false
$SubmitButton.DialogResult          = [System.Windows.Forms.DialogResult]::OK
$ConfigOperationsForm.CancelButton   = $SubmitButton
$ConfigOperationsForm.Controls.Add($SubmitButton)


$BottomLabel            = New-Object system.Windows.Forms.Label
$BottomLabel.text       = "Contact : utsav.tyagi@corecard.com"
$BottomLabel.AutoSize   = $true
$BottomLabel.width      = 50
$BottomLabel.height     = 10
$BottomLabel.location   = New-Object System.Drawing.Point(315,485)
$BottomLabel.Font       = 'Microsoft Sans Serif,8'

$ConfigOperationsForm.controls.AddRange(@($Title,$EnvironmentNameLabel,$ProjectLabel,$PODsComboBox,$StacksComboBox,$OperationsComboBox,$JobsComboBox,$ProcessTaskLabel,$ProcessTaskComboBox,$AZsLabel,$AZsComboBox,$ServerTypesLabel, $ServerTypesComboBox,$ServerRangeLabel,$ServerRangeStartLabel,$ServerRangeStart,$ServerRangeEndLabel,$ServerRangeEnd,$BottomLabel))

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Clear-Host

$Results=  $ConfigOperationsForm.ShowDialog()


$SelectedProcesses = @()



if ($Results -eq [System.Windows.Forms.DialogResult]::OK)
{
Clear-Host
#Write-Host "Entered text is" -ForegroundColor Green
Write-Host "PROJECT" -ForegroundColor Blue -BackgroundColor White
Write-Host $ProjectName

Write-Host `n "POD" -ForegroundColor Blue -BackgroundColor White
Write-Host $PODsComboBox.SelectedItem.ToString()

Write-Host `n "Stack" -ForegroundColor Blue -BackgroundColor White
Write-Host $StacksComboBox.SelectedItem.ToString()

Write-Host `n "Operation" -ForegroundColor Blue -BackgroundColor White
Write-Host $OperationsComboBox.SelectedItem.ToString()

Write-Host `n "Job" -ForegroundColor Blue -BackgroundColor White
Write-Host $JobsComboBox.SelectedItem.ToString()

Write-Host `n "Processes Name / Tasks Name / Websites Name" -ForegroundColor Blue -BackgroundColor White
$ProcessTaskComboBox.CheckedItems

#Write-Host "Process Name / Task Name - " $ProcessTaskComboBox.CheckedItems.Count
#for($i=0; $i -lt $ProcessTaskComboBox.CheckedItems.Count; $i++){
#$SelectedProcesses += $ProcessTaskComboBox.CheckedItems.Item($i)
#}
#$SelectedProcesses

#foreach($SelectedProcess in $SelectedProcesses){$SelectedProcess}

#Write-Host "Process Name / Task Name - " $ProcessTaskComboBox.SelectedItem.ToString()

Write-Host `n "Availability Zone"  -ForegroundColor Blue -BackgroundColor White
$AZsComboBox.CheckedItems

Write-Host `n "Server Range" -ForegroundColor Blue -BackgroundColor White
Write-Host $ServerRangeStart.Value.ToString() - $ServerRangeEnd.Value.ToString()


Write-Host `n "Server Type" -ForegroundColor Blue -BackgroundColor White
$ServerTypesComboBox.CheckedItems


Write-Host ""

Read-Host "Verify and Press Enter"
}else {
Clear-Host
Write-Host "Exiting" -ForegroundColor Red
Break Script}

Write-Host "Performing given action..." -ForegroundColor Green -


#$OperationsComboBox.SelectedItem.ToString()
#$JobsComboBox.SelectedItem.ToString()
#$ProcessTaskComboBox.CheckedItems
#$AZsComboBox.CheckedItems
#$ServerRangeStart.Value.ToString()
#$ServerRangeEnd.Value.ToString()
#$ServerTypesComboBox.CheckedItems


If($JobsComboBox.SelectedItem.ToString() -match "Copy "){

$Script:CompressedFileName = $JobsComboBox.SelectedItem.ToString().Split(" ")[1] + ".zip"
#$Script:CompressedFileName

$CompressedFilePath =  join-path -path $Script:CopySourcePathArchive -childpath $Script:CompressedFileName
$PODS3 = $PODsComboBox.SelectedItem.ToString().Split("-")[1].ToLower()

$CopyPathS3 = $NULL
$CopyPathS3 = "s3://corecard-$PODS3-$EnvironmentName-$Region-config-files/COPYFILES/$CompressedFileName"


$compressfiles = @{
  Path = "$CopySourcePath\*"
  CompressionLevel = "Fastest"
  DestinationPath = "$CompressedFilePath"
  Force = $True}

Compress-Archive @compressfiles

aws s3 rm $CopyPathS3 # --recursive
aws s3 cp $CompressedFilePath $CopyPathS3
#Read-Host "Wait"

#Read-Host "Copy Copy Copy"


}






$ServerList = $NULL
$ServerList = @()
$ServerListAZST = $NULL
$ServerListAZST = @()


ForEach($ServerType in $ServerTypesComboBox.CheckedItems) {

Write-Host "ServerTpye - $ServerType" -ForegroundColor Blue -BackgroundColor White


ForEach($AZItem in $AZsComboBox.CheckedItems) {

#Write-Host "Availability Zone" $AZItem  -ForegroundColor Blue -BackgroundColor White
IF($ServerType -eq "bat"){
$ServerListAZST = (((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName*'" "Name=availability-zone,Values='$AZItem'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } },@{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double](($_.Name -split "$EnvironmentName")[1] -replace "[^0-9]",'') } } |Sort-Object -Property serial) | Where-Object -Property serial -ge $ServerRangeStart.Value | Where-Object -Property serial -le $ServerRangeEnd.Value )
}else{
$ServerListAZST = (((aws ec2 describe-instances --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$script:EnvironmentStack*'" "Name=availability-zone,Values='$AZItem'" --region $Region | ConvertFrom-Json) | Select-Object @{n = "Name"; e = { $_.Name } },@{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, @{n = "serial"; e = { [double]($_.Name -split "$EnvironmentName$script:EnvironmentStack")[1] } } |Sort-Object -Property serial) | Where-Object -Property serial -ge $ServerRangeStart.Value | Where-Object -Property serial -le $ServerRangeEnd.Value )
}
$ServerListAZST | Out-Host
$ServerList += $ServerListAZST
}
}
$ServerList = $ServerList.Name
#$ServerList | Out-Host

if ($ServerList -eq $NULL) {
Write-Host "No Server in the the gven criteria... Please try again"
Break Script
}


Read-Host "Please verify the server list and press enter to continue or Stop the script"



$option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
Invoke-Command -ComputerName $ServerList -SessionOption $option -ErrorAction inquire -ScriptBlock {

param ($EnvironmentName, $OperationsParam, $JobsParam, $ProcessTasksParam, $CopyPathS3Param)

$computername = hostname

if($OperationsParam -eq "Process Management"){
#if($ProcessTasksParam -eq "ALL"){$ProcessTasksParam = 'DbbAppServer*', 'Rundbb*'}
#$ProcessTasksParam
#Write-Host "1. Process Management"
If ($JobsParam  -eq "Stop Processes") {
#if($ProcessTasksParam -eq "ALL"){$ProcessTasksParam = 'Task_*'}
$ProcessTasksListNames = $NULL
$ProcessTasksListNames = (Get-Process -Name $ProcessTasksParam).Name
If ($ProcessTasksListNames -ne $NULL){Write-Host "Process stopping on "  $computername :  $ProcessTasksListNames
Get-Process -Name $ProcessTasksListNames | Stop-Process -Force}
else{Write-Host "Process Stopping on "  $computername ": " "No Process to Stop"}
}
    
If ($JobsParam  -eq "Start Processes") {
$ProcessTasksListNames = $NULL
$ProcessTasksListNames = (Get-ScheduledTask  -TaskName $ProcessTasksParam -ErrorAction SilentlyContinue | Start-ScheduledTask -ErrorAction SilentlyContinue).TaskName
If((Get-ScheduledTask  -TaskName $ProcessTasksParam -ErrorAction SilentlyContinue) -ne $NULL){
Write-Host "Process starting on "  $computername ": " (((Get-ScheduledTask  -TaskName $ProcessTasksParam -ErrorAction SilentlyContinue).TaskName).replace("Task_","  Task_"))#
}
#else{Write-Host "Process starting on "  $computername ": " "No Process to Start"}
}
}

elseif($OperationsParam -eq "Task Management"){

If ($JobsParam -eq "Disable Tasks") {
$ProcessTasksListNames = $NULL
foreach ($Task in $ProcessTasksParam){
$ProcessTasksListNames += (Get-ScheduledTask  -TaskName "*$Task*" -ErrorAction SilentlyContinue | Disable-ScheduledTask).TaskName}
if ($ProcessTasksListNames -ne $NULL){Write-Host "Disabled Jobs on "  $computername ":"  $ProcessTasksListNames.replace("Task_","  Task_")}
#else{Write-Host "Process starting on "  $computername ": " "No Task to Disable"}

}
If ($JobsParam  -eq "Enable Tasks") {
$ProcessTasksListNames = $NULL
foreach ($Task in $ProcessTasksParam){
$ProcessTasksListNames += (Get-ScheduledTask  -TaskName "*$Task*" -ErrorAction SilentlyContinue | Enable-ScheduledTask).TaskName}
if ($ProcessTasksListNames -ne $NULL){Write-Host "Enabled Jobs on "  $computername ":"  $ProcessTasksListNames.replace("Task_","  Task_")}
#else{Write-Host "Process starting on "  $computername ": " "No Task to Enable"}

}
}

elseif($OperationsParam -eq "IIS Management"){

If ($JobsParam -eq "Stop IIS"){
$IISResetResult = IISRESET /stop
Write-Host $computername  $IISResetResult}

If ($JobsParam -eq "Start IIS"){
$IISResetResult = IISRESET /start
Write-Host $computername  $IISResetResult} 

If ($JobsParam -eq "Reset IIS"){
$IISResetResult = IISRESET
Write-Host $computername  $IISResetResult} 

If ($JobsParam -eq "Stop and Disable W3SVC"){
$W3SVCService = Get-WmiObject Win32_Service  -filter "Name = 'W3SVC'" 
$W3SVCService.stopservice()
$W3SVCService.ChangeStartMode("Disabled")  
Write-Host $computername  " - Stop and Disable W3SVC"}

If ($JobsParam -eq "Enable and Start W3SVC"){
$W3SVCService = Get-WmiObject Win32_Service  -filter "Name = 'W3SVC'" 
$W3SVCService.ChangeStartMode("Automatic")  
$W3SVCService.startservice()
Write-Host $computername  " - Enable and Start W3SVC"}

If ($JobsParam -eq "Stop ScaleService"){
Get-Process -Name dbbScaleService | Stop-Process -Force
Write-Host $computername  " - Stop ScaleService"} 

If ($JobsParam -eq "Start ScaleService"){
$ScaleService = Get-WmiObject Win32_Service  -filter "Name = 'DbbScaleService'" 
$ScaleService.startservice()
Write-Host $computername  " - Start ScaleService"}

If ($JobsParam -eq "Recycle AppPool"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Restart-WebAppPool $WebAppPool
$WebAppPool
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool Recyled..."
}
}

If ($JobsParam -eq "Set Connect As - ccgs-app-svc"){
$EnvironmentName = $EnvironmentName.ToUpper()
$SecretObj = (Get-SECSecretValue -Secretid "$EnvironmentName/app-service-secret")
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$DomainName = ($Secret.domainNetBIOSName).ToUpper()
$Username = $Secret.username
$DomainUsername = "$DomainName\$Username"
#$Password = $Secret.password
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
Set-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/$Site']/VirtualDirectory[@path='/']" -Value @{userName = $DomainUsername; password = $Secret.password}

}else{
Set-WebConfiguration "/system.applicationHost/sites/site[@name='$Site']/application[@path='/']/VirtualDirectory[@path='/']" -Value @{userName = $DomainUsername; password = $Secret.password}
}
Write-Host "$computername; Website - $Site; ConnectAs - $Username"
}
}

If ($JobsParam -eq "Set Connect As - ccgs-app-upg"){
$EnvironmentName = $EnvironmentName.ToUpper()
$SecretObj = (Get-SECSecretValue -Secretid "$EnvironmentName/app-upgrade-secret")
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$DomainName = ($Secret.domainNetBIOSName).ToUpper()
$Username = $Secret.username
$DomainUsername = "$DomainName\$Username"
#$Password = $Secret.password
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
Set-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/$Site']/VirtualDirectory[@path='/']" -Value @{userName = $DomainUsername; password = $Secret.password}

}else{
Set-WebConfiguration "/system.applicationHost/sites/site[@name='$Site']/application[@path='/']/VirtualDirectory[@path='/']" -Value @{userName = $DomainUsername; password = $Secret.password}
}
Write-Host "$computername; Website - $Site; ConnectAs - $Username"
}
}

If ($JobsParam -eq "Set Connect As - ccgs-web-svc"){
$EnvironmentName = $EnvironmentName.ToUpper()
$SecretObj = (Get-SECSecretValue -Secretid "$EnvironmentName/web-service-secret")
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$DomainName = ($Secret.domainNetBIOSName).ToUpper()
$Username = $Secret.username
$DomainUsername = "$DomainName\$Username"
#$Password = $Secret.password
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
Set-WebConfiguration "/system.applicationHost/sites/site[@name='Webserver']/application[@path='/$Site']/VirtualDirectory[@path='/']" -Value @{userName = $DomainUsername; password = $Secret.password}

}else{
Set-WebConfiguration "/system.applicationHost/sites/site[@name='$Site']/application[@path='/']/VirtualDirectory[@path='/']" -Value @{userName = $DomainUsername; password = $Secret.password}
}
Write-Host "$computername; Website - $Site; ConnectAs - $DomainUsername"
}
}

If ($JobsParam -eq "Set AppPool User - ccgs-app-svc"){
$EnvironmentName = $EnvironmentName.ToUpper()
$SecretObj = (Get-SECSecretValue -Secretid "$EnvironmentName/app-service-secret")
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$DomainName = ($Secret.domainNetBIOSName).ToUpper()
$Username = $Secret.username
$DomainUsername = "$DomainName\$Username"
#$Password = $Secret.password
Import-Module WebAdministration
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Restart-WebAppPool $WebAppPool
$WebAppPool
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel -value @{userName = $DomainUsername; password = $Secret.password; identitytype = 3 }

Write-Host "$computername; Website - $Site; ; AppPool - $WebAppPool; User - $DomainUsername"
}
} 

If ($JobsParam -eq "Set AppPool User - ccgs-app-upg"){
$EnvironmentName = $EnvironmentName.ToUpper()
$SecretObj = (Get-SECSecretValue -Secretid "$EnvironmentName/app-upgrade-secret")
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$DomainName = ($Secret.domainNetBIOSName).ToUpper()
$Username = $Secret.username
$DomainUsername = "$DomainName\$Username"
#$Password = $Secret.password
Import-Module WebAdministration
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Restart-WebAppPool $WebAppPool
$WebAppPool
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel -value @{userName = $DomainUsername; password = $Secret.password; identitytype = 3 }

Write-Host "$computername; Website - $Site; ; AppPool - $WebAppPool; User - $DomainUsername"
}
} 

If ($JobsParam -eq "Set AppPool User - ccgs-web-svc"){
$EnvironmentName = $EnvironmentName.ToUpper()
$SecretObj = (Get-SECSecretValue -Secretid "$EnvironmentName/web-service-secret")
$Secret = $SecretObj.SecretString | ConvertFrom-Json
$DomainName = ($Secret.domainNetBIOSName).ToUpper()
$Username = $Secret.username
$DomainUsername = "$DomainName\$Username"
#$Password = $Secret.password
Import-Module WebAdministration
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Restart-WebAppPool $WebAppPool
$WebAppPool
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel -value @{userName = $DomainUsername; password = $Secret.password; identitytype = 3 }

Write-Host "$computername; Website - $Site; ; AppPool - $WebAppPool; User - $DomainUsername"
}
}

If ($JobsParam -eq "Set X-Request-ID"){
Import-Module WebAdministration
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
New-ItemProperty 'IIS:\Sites\Webserver' -Name logfile.customFields.collection -Value @{logFieldName='X-Request-ID';sourceType='RequestHeader';sourceName='X-Request-ID'}
New-ItemProperty 'IIS:\Sites\Webserver' -Name logfile.customFields.collection -Value @{logFieldName='X-Request-ID';sourceType='RequestHeader';sourceName='X-Request-ID'}
}else{
New-ItemProperty 'IIS:\Sites\$Site' -Name logfile.customFields.collection -Value @{logFieldName='X-Request-ID';sourceType='RequestHeader';sourceName='X-Request-ID'}
New-ItemProperty 'IIS:\Sites\$Site' -Name logfile.customFields.collection -Value @{logFieldName='X-Request-ID';sourceType='RequestHeader';sourceName='X-Request-ID'}
}
Write-Host "$computername; Website - $Site; X-Request-ID - Enabled"
}
}

If ($JobsParam -eq "Disable IIS Logging"){
Import-Module WebAdministration
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
Set-ItemProperty -Path 'IIS:\Sites\Webserver' -Name Logfile.enabled -Value $false
}else{
Set-ItemProperty -Path 'IIS:\Sites\$Site' -Name Logfile.enabled -Value $false
}
Write-Host "$computername; Website - $Site; IIS Logging - Disabled"
}
}

If ($JobsParam -eq "Enable IIS Logging"){
Import-Module WebAdministration
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
Set-ItemProperty -Path 'IIS:\Sites\Webserver' -Name Logfile.enabled -Value $true
}else{
Set-ItemProperty -Path 'IIS:\Sites\$Site' -Name Logfile.enabled -Value $true
}
Write-Host "$computername; Website - $Site; IIS Logging - Enabled"
}
}

If ($JobsParam -eq "Set Worker Process 1"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel -value @{maxProcesses = 1}
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; MaxProcesses = (Get-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel).maxProcesses"
}
}

If ($JobsParam -eq "Set Worker Process 4"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel -value @{maxProcesses = 4}
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; MaxProcesses = (Get-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel).maxProcesses"
}
}

If ($JobsParam -eq "Set Worker Process 64"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel -value @{maxProcesses = 64}
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; MaxProcesses = (Get-ItemProperty "IIS:\AppPools\$WebAppPool" -name processModel).maxProcesses"
}
}

If ($JobsParam -eq "Enable32bitApplication True"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty IIS:\AppPools\$WebAppPool -Name enable32BitAppOnWin64 -Value 'true'
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; MaxProcesses = (Get-ItemProperty IIS:\AppPools\$WebAppPool -Name enable32BitAppOnWin64).Value"
}
}

If ($JobsParam -eq "Enable32bitApplication False"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty IIS:\AppPools\$WebAppPool -Name enable32BitAppOnWin64 -Value 'false'
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; MaxProcesses = (Get-ItemProperty IIS:\AppPools\$WebAppPool -Name enable32BitAppOnWin64).Value"
}
}

If ($JobsParam -eq "IdleTimeoutAction Terminate"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -Name processModel.idleTimeoutAction -Value Terminate
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; IdleTimeoutAction = Get-ItemProperty IIS:\AppPools\$WebAppPool -Name processModel.idleTimeoutAction"
}
}

If ($JobsParam -eq "IdleTimeoutAction Suspend"){
foreach($Site in $ProcessTasksParam){
If(($Site -eq "WCF") -or ($Site -eq "CoreCardServices")){
$WebAppPool = (Get-WebApplication -name $Site | Where ItemXPath -Match "Webserver").applicationPool
}else{
$WebAppPool = (Get-Website -Name $Site).applicationPool}
Set-ItemProperty "IIS:\AppPools\$WebAppPool" -Name processModel.idleTimeoutAction -Value Suspend
Write-Host "$computername; WebSite - $Site Web; WebAppPool- $WebAppPool; IdleTimeoutAction = Get-ItemProperty IIS:\AppPools\$WebAppPool -Name processModel.idleTimeoutAction"
}
}



}


elseif($OperationsParam -eq "File Management"){

write-host  $computername

#if(Test-Path -Path D:\TEST\){
#Remove-Item -Force -Path D:\TEST\ -Recurse}

If ($JobsParam -match "Copy"){
$CompressedFileNameonDestServer = $JobsParam.Split(" ")[1] + ".zip"

if(Test-Path -Path C:\TEMP\$CompressedFileNameonDestServer) {Remove-Item -Force -Path "C:\TEMP\$CompressedFileNameonDestServer"}
aws s3 cp $CopyPathS3Param "C:\TEMP\$CompressedFileNameonDestServer"
Expand-Archive -Path "C:\TEMP\$CompressedFileNameonDestServer" -DestinationPath D:\ -Force
}

}

else{
Write-Host "$RunJob. Invalid Option"
}


} -ArgumentList $EnvironmentName, $OperationsComboBox.SelectedItem.ToString(), $JobsComboBox.SelectedItem.ToString(), $ProcessTaskComboBox.CheckedItems, $CopyPathS3


Read-Host "Press Enter to continue"

} while (1 -eq 1)

