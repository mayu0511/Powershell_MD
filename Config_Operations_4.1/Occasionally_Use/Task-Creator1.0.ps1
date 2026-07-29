######################################################################################################################
# Task Creator (GUI)  |  DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | GUI Release | Date:: 27-July-2026
######################################################################################################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

Clear-Host

#-----------------------------------------------------------------------------------------------
# STATIC CONFIG
#-----------------------------------------------------------------------------------------------

# Task Type -> Executable / WorkingDirectory map
$TaskTypeMap = @{
    "CoreIssue" = @{
        Executable       = "D:\DBBSetup\BatchScripts\CoreIssue\RunccCI.bat"
        WorkingDirectory = "D:\DBBSetup\BatchScripts\CoreIssue"
    }
    "CoreAuth" = @{
        Executable       = "D:\DBBSetup\BatchScripts\CoreAuth\RunccCoreAuth.bat"
        WorkingDirectory = "D:\DBBSetup\BatchScripts\CoreAuth"
    }
}

# Server types that map to the App-Svc gMSA account
$AppSvcServerTypes = @('svc', 'iss', 'aut', 'src', 'snk', 'awf', 'tnp')
# Server types that map to the Batch-Svc gMSA account
$BatchSvcServerTypes = @('bat')
# All server types we will search for during discovery
$ServerTypeList = $AppSvcServerTypes + $BatchSvcServerTypes

$TaskConfig = @{
    "Task_DbbAppServer_Services"       = @{ TriggerID = 2;  Port = 7011 }
    "Task_DbbAppServer_CoreIssue"      = @{ TriggerID = 1;  Port = 7012 }
    "Task_DbbAppServer_CoreAuth"       = @{ TriggerID = 1;  Port = 7013 }
    "Task_MCSource"                    = @{ TriggerID = 4;  Port = 7014 }
    "Task_CoreAuthManualAdminMessage"  = @{ TriggerID = 3;  Port = 7015 }
    "Task_MCSink"                      = @{ TriggerID = 5;  Port = 7016 }
    "Task_TNP"                         = @{ TriggerID = 3;  Port = 7017 }
    "Task_ETNP"                        = @{ TriggerID = 20; Port = 7018 }
    "Task_AccountReinstate"            = @{ TriggerID = 23; Port = 7019 }
    "Task_AlertNotification"           = @{ TriggerID = 14; Port = 7020 }
    "Task_BatchNotification"           = @{ TriggerID = 24; Port = 7021 }
    "Task_BatchNotification2"          = @{ TriggerID = 35; Port = 7022 }
    "Task_CoreAuthAging"               = @{ TriggerID = 2;  Port = 7023 }
    "Task_CoreAuthRetryAlert"          = @{ TriggerID = 6;  Port = 7024 }
    "Task_CoreIssueRetryAlert"         = @{ TriggerID = 16; Port = 7025 }
    "Task_DBPD"                        = @{ TriggerID = 4;  Port = 7026 }
    "Task_MergeAccounts"               = @{ TriggerID = 32; Port = 7027 }
    "Task_MSMQ"                        = @{ TriggerID = 5;  Port = 7028 }
    "Task_RetailAuthJobs"              = @{ TriggerID = 22; Port = 7029 }
    "Task_RewardAutoRedeem"            = @{ TriggerID = 15; Port = 7030 }
    "Task_RewardNotification"          = @{ TriggerID = 21; Port = 7031 }
    "Task_UpdateCall"                  = @{ TriggerID = 8;  Port = 7032 }
    "Task_ACHCreatePIIRequest_Cookie1" = @{ TriggerID = 26; Port = 7033 }
    "Task_ACHSendPIIRequest_Cookie1"   = @{ TriggerID = 27; Port = 7034 }
    "Task_ACHCreatePIIRequest_Cookie2" = @{ TriggerID = 33; Port = 7035 }
    "Task_ACHSendPIIRequest_Cookie2"   = @{ TriggerID = 34; Port = 7036 }
    "Task_AccountCreation"             = @{ TriggerID = 10; Port = 7037 }
    "Task_ThirdPartyAlerts"            = @{ TriggerID = 18; Port = 7038 }
    "Task_ThirdPartyAlertsCBES"        = @{ TriggerID = 37; Port = 7039 }
    "Task_CBRCreatePIIRequest_Cookie1" = @{ TriggerID = 28; Port = 7040 }
    "Task_CBRCreatePIIRequest_Cookie2" = @{ TriggerID = 30; Port = 7041 }
    "Task_CBRSendPIIRequest_Cookie1"   = @{ TriggerID = 29; Port = 7042 }
    "Task_CBRSendPIIRequest_Cookie2"   = @{ TriggerID = 31; Port = 7043 }
    "Task_BillPayPayment"              = @{ TriggerID = 17; Port = 7044 }
    "Task_LockBox"                     = @{ TriggerID = 12; Port = 7045 }
    "Task_IPMSettlement"               = @{ TriggerID = 9;  Port = 7046 }
    "Task_IrvingOutgoingEmbossing"     = @{ TriggerID = 13; Port = 7047 }
    "Task_ExtractCBR_Retry"            = @{ TriggerID = 42; Port = 7052 }
    "Task_BroadcastMsgAcrossPOD"       = @{ TriggerID = 41; Port = 7053 }
    "Task_RewardPromoDetails"          = @{ TriggerID = 44; Port = 7054 }
    "Task_PendingTxn"                  = @{ TriggerID = 45; Port = 7055 }
    "Task_APJob"                       = @{ TriggerID = 46; Port = 7056 }
    "Task_APIQueue"                    = @{ TriggerID = 48; Port = 7057 }
    "Task_BulkCardFileValidator"       = @{ TriggerID = 49; Port = 7058 }
}

$TaskNameChoices = $TaskConfig.Keys | Sort-Object

#-----------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
#-----------------------------------------------------------------------------------------------

function Get-ServerTypeFromName {
    param([string]$Name, [string]$EnvironmentName, [string]$EnvironmentStack, [string]$ShortRegion)

    foreach ($Type in $ServerTypeList) {
        if ($Name -match [regex]::Escape("$Type$ShortRegion$EnvironmentName$EnvironmentStack")) {
            return $Type
        }
    }
    return $null
}

function Get-UserIdForServerType {
    param([string]$ServerType, [string]$Pod, [string]$EnvironmentName)

    if ($AppSvcServerTypes -contains $ServerType) {
        return "cc-$Pod-$EnvironmentName\gmsa-app-svc`$"
    }
    elseif ($BatchSvcServerTypes -contains $ServerType) {
        return "cc-$Pod-$EnvironmentName\gmsa-batch-svc`$"
    }
    else {
        return $null
    }
}

#-----------------------------------------------------------------------------------------------
# STEP 1 - REGION / ENVIRONMENT DISCOVERY (same logic as original script)
#-----------------------------------------------------------------------------------------------

$ThisServer = (Hostname).ToLower()
$Region = $null
$ShortRegion = $null

if ($ThisServer -match 'e1') {
    $Region = "us-east-1"
    $ShortRegion = 'e1'
}
elseif ($ThisServer -match 'w2') {
    $Region = "us-west-2"
    $ShortRegion = 'w2'
}

if (-not $Region) {
    [System.Windows.Forms.MessageBox]::Show("Could not determine region from hostname '$ThisServer'. Expected 'e1' or 'w2' in the hostname.", "Region Detection Failed", 'OK', 'Error') | Out-Null
    return
}

$AWSVariables = (aws ec2 describe-instances `
        --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,Environment:Tags[?Key=='environment']|[0].Value,Stack:Tags[?Key=='stack']|[0].Value,Attribution:Tags[?Key=='attribution']|[0].Value}" `
        --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='$ThisServer'" "Name=availability-zone,Values='*'" `
        --region $Region | ConvertFrom-Json)

$EnvironmentName      = $AWSVariables.Environment.ToLower()
$EnvironmentStack     = ($AWSVariables.Stack.ToLower())[0]

$AvailabilityZonesDefaultServerType = "tnp"
$AvailabilityZones = ((aws ec2 describe-instances `
            --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" `
            --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$AvailabilityZonesDefaultServerType$ShortRegion$EnvironmentName$EnvironmentStack*'" "Name=availability-zone,Values='*'" `
            --region $Region | ConvertFrom-Json).AvailabilityZone) | Get-Unique

#-----------------------------------------------------------------------------------------------
# GLOBAL RUNTIME STATE
#-----------------------------------------------------------------------------------------------

$Script:DiscoveredServers = @()   # sorted array of server objects: Name, AvailabilityZone, ServerType, UserId
$Script:DiscoveredServerTypes = @()   # which Server Types were checked at the time of the last successful discovery

#-----------------------------------------------------------------------------------------------
# STEP 2 - BUILD THE FORM
#-----------------------------------------------------------------------------------------------

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Task Creator By Mahendra Dwivedi"
$DesiredHeight = 690
$MaxHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height - 60
$Form.Size = New-Object System.Drawing.Size(760, [Math]::Min($DesiredHeight, $MaxHeight))

$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = 'Sizable'
$Form.MaximizeBox = $true
$Form.MinimizeBox = $true
$Form.AutoScroll = $true

# ---- Group: Discovery ----
$grpDiscovery = New-Object System.Windows.Forms.GroupBox
$grpDiscovery.Text = "1. Server Discovery"
$grpDiscovery.Location = New-Object System.Drawing.Point(10, 10)
$grpDiscovery.Size = New-Object System.Drawing.Size(720, 95)
$Form.Controls.Add($grpDiscovery)

# Availability Zone
$lblAZ = New-Object System.Windows.Forms.Label
$lblAZ.Location = New-Object System.Drawing.Point(15,28)
$lblAZ.Size = New-Object System.Drawing.Size(95,20)
$lblAZ.Text = "Availability Zone:"
$grpDiscovery.Controls.Add($lblAZ)

$cmbAZ = New-Object System.Windows.Forms.ComboBox
$cmbAZ.Location = New-Object System.Drawing.Point(120,25)
$cmbAZ.Size = New-Object System.Drawing.Size(120,21)
$cmbAZ.DropDownStyle = 'DropDownList'
$cmbAZ.Items.Add("*") | Out-Null
foreach($az in $AvailabilityZones){
    $cmbAZ.Items.Add($az) | Out-Null
}
$cmbAZ.SelectedIndex = 0
$grpDiscovery.Controls.Add($cmbAZ)

# POD
$lblPOD = New-Object System.Windows.Forms.Label
$lblPOD.Location = New-Object System.Drawing.Point(250,28)
$lblPOD.Size = New-Object System.Drawing.Size(35,20)
$lblPOD.Text = "POD:"
$grpDiscovery.Controls.Add($lblPOD)

$cmbPOD = New-Object System.Windows.Forms.ComboBox
$cmbPOD.Location = New-Object System.Drawing.Point(290,25)
$cmbPOD.Size = New-Object System.Drawing.Size(110,21)
$cmbPOD.DropDownStyle = 'DropDownList'

"POD1","POD2","POD3","POD4","POD5" | ForEach-Object{
    [void]$cmbPOD.Items.Add($_)
}

$cmbPOD.SelectedIndex = 0
$grpDiscovery.Controls.Add($cmbPOD)

# Stack
$lblStack = New-Object System.Windows.Forms.Label
$lblStack.Location = New-Object System.Drawing.Point(415,28)
$lblStack.Size = New-Object System.Drawing.Size(40,20)
$lblStack.Text = "Stack:"
$grpDiscovery.Controls.Add($lblStack)

$cmbStack = New-Object System.Windows.Forms.ComboBox
$cmbStack.Location = New-Object System.Drawing.Point(465,25)
$cmbStack.Size = New-Object System.Drawing.Size(100,21)
$cmbStack.DropDownStyle = 'DropDownList'

"Blue","Green" | ForEach-Object{
    [void]$cmbStack.Items.Add($_)
}

$cmbStack.SelectedIndex = 0
$grpDiscovery.Controls.Add($cmbStack)

# Discover Button
$btnDiscover = New-Object System.Windows.Forms.Button
$btnDiscover.Text = "Discover Servers"
$btnDiscover.Location = New-Object System.Drawing.Point(575,23)
$btnDiscover.Size = New-Object System.Drawing.Size(120,28)
$grpDiscovery.Controls.Add($btnDiscover)

$lblDiscoverStatus = New-Object System.Windows.Forms.Label
$lblDiscoverStatus.Text = "No servers discovered yet."
$lblDiscoverStatus.Location = New-Object System.Drawing.Point(10, 65)
$lblDiscoverStatus.Size = New-Object System.Drawing.Size(690, 20)
$lblDiscoverStatus.ForeColor = [System.Drawing.Color]::DarkRed
$grpDiscovery.Controls.Add($lblDiscoverStatus)

# ---- Group: Task Configuration ----
$grpTask = New-Object System.Windows.Forms.GroupBox
$grpTask.Text = "2. Task Configuration"
$grpTask.Location = New-Object System.Drawing.Point(10, 120)
$grpTask.Size = New-Object System.Drawing.Size(720, 220)
$Form.Controls.Add($grpTask)

$lblTaskType = New-Object System.Windows.Forms.Label
$lblTaskType.Text = "Task Type:"
$lblTaskType.Location = New-Object System.Drawing.Point(10, 30)
$lblTaskType.Size = New-Object System.Drawing.Size(90, 20)
$grpTask.Controls.Add($lblTaskType)

$rbCoreIssue = New-Object System.Windows.Forms.RadioButton
$rbCoreIssue.Text = "CoreIssue"
$rbCoreIssue.Location = New-Object System.Drawing.Point(130, 28)
$rbCoreIssue.Size = New-Object System.Drawing.Size(90, 20)
$rbCoreIssue.Checked = $true
$grpTask.Controls.Add($rbCoreIssue)

$rbCoreAuth = New-Object System.Windows.Forms.RadioButton
$rbCoreAuth.Text = "CoreAuth"
$rbCoreAuth.Location = New-Object System.Drawing.Point(230, 28)
$rbCoreAuth.Size = New-Object System.Drawing.Size(90, 20)
$grpTask.Controls.Add($rbCoreAuth)

$lblExe = New-Object System.Windows.Forms.Label
$lblExe.Text = "Executable Path:"
$lblExe.Location = New-Object System.Drawing.Point(10, 60)
$lblExe.Size = New-Object System.Drawing.Size(110, 20)
$grpTask.Controls.Add($lblExe)

$txtExe = New-Object System.Windows.Forms.TextBox
$txtExe.Location = New-Object System.Drawing.Point(130, 57)
$txtExe.Size = New-Object System.Drawing.Size(560, 20)
$txtExe.ReadOnly = $true
$txtExe.Text = $TaskTypeMap["CoreIssue"].Executable
$grpTask.Controls.Add($txtExe)

$lblWorkDir = New-Object System.Windows.Forms.Label
$lblWorkDir.Text = "Working Directory:"
$lblWorkDir.Location = New-Object System.Drawing.Point(10, 90)
$lblWorkDir.Size = New-Object System.Drawing.Size(110, 20)
$grpTask.Controls.Add($lblWorkDir)

$txtWorkDir = New-Object System.Windows.Forms.TextBox
$txtWorkDir.Location = New-Object System.Drawing.Point(130, 87)
$txtWorkDir.Size = New-Object System.Drawing.Size(560, 20)
$txtWorkDir.ReadOnly = $true
$txtWorkDir.Text = $TaskTypeMap["CoreIssue"].WorkingDirectory
$grpTask.Controls.Add($txtWorkDir)

$lblArg = New-Object System.Windows.Forms.Label
$lblArg.Text = "Argument Value:"
$lblArg.Location = New-Object System.Drawing.Point(10, 120)
$lblArg.Size = New-Object System.Drawing.Size(110, 20)
$grpTask.Controls.Add($lblArg)

$txtArg = New-Object System.Windows.Forms.TextBox
$txtArg.Location = New-Object System.Drawing.Point(130, 117)
$txtArg.Size = New-Object System.Drawing.Size(200, 20)
$txtArg.Text = "1 7012"
$grpTask.Controls.Add($txtArg)

$lblTrigger = New-Object System.Windows.Forms.Label
$lblTrigger.Text = "Trigger:"
$lblTrigger.Location = New-Object System.Drawing.Point(10, 150)
$lblTrigger.Size = New-Object System.Drawing.Size(90, 20)
$grpTask.Controls.Add($lblTrigger)

$lblTriggerValue = New-Object System.Windows.Forms.Label
$lblTriggerValue.Text = "AtStartup (fixed)"
$lblTriggerValue.Location = New-Object System.Drawing.Point(130, 150)
$lblTriggerValue.Size = New-Object System.Drawing.Size(200, 20)
$lblTriggerValue.Font = New-Object System.Drawing.Font($lblTriggerValue.Font, [System.Drawing.FontStyle]::Bold)
$grpTask.Controls.Add($lblTriggerValue)

$lblTaskName = New-Object System.Windows.Forms.Label
$lblTaskName.Text = "Task Name:"
$lblTaskName.Location = New-Object System.Drawing.Point(10, 180)
$lblTaskName.Size = New-Object System.Drawing.Size(90, 20)
$grpTask.Controls.Add($lblTaskName)

$cmbTaskName = New-Object System.Windows.Forms.ComboBox
$cmbTaskName.Location = New-Object System.Drawing.Point(130, 177)
$cmbTaskName.Size = New-Object System.Drawing.Size(320, 20)
$cmbTaskName.DropDownStyle = 'DropDownList'
foreach ($t in $TaskNameChoices) { $cmbTaskName.Items.Add($t) | Out-Null }
$cmbTaskName.SelectedIndex = 0
$cmbTaskName.Add_SelectedIndexChanged({

    $TaskName = $cmbTaskName.Text.Trim()

    if ($TaskConfig.ContainsKey($TaskName)) {

        $TaskInfo = $TaskConfig[$TaskName]

        $txtArg.Text = "$($TaskInfo.TriggerID) $($TaskInfo.Port)"
    }

})

if ($cmbTaskName.Items.Count -gt 0) {

    $cmbTaskName.SelectedIndex = 0

    $TaskName = $cmbTaskName.Text.Trim()

    if ($TaskConfig.ContainsKey($TaskName)) {

        $TaskInfo = $TaskConfig[$TaskName]

        $txtArg.Text = "$($TaskInfo.TriggerID) $($TaskInfo.Port)"
    }
}

$UpdateTaskArgument = {

    $TaskName = $cmbTaskName.SelectedItem.ToString()

    if ($TaskConfig.ContainsKey($TaskName)) {

        $TriggerID = $TaskConfig[$TaskName].TriggerID
        $Port      = $TaskConfig[$TaskName].Port

        # Display in textbox
        $txtArg.Text = "$TriggerID $Port"

        # If your scheduled task requires switches instead:
        # $txtArg.Text = "-TriggerID $TriggerID -Port $Port"
    }
}

$cmbTaskName.Add_SelectedIndexChanged($UpdateTaskArgument)

# Populate the textbox for the default selection
& $UpdateTaskArgument

$grpTask.Controls.Add($cmbTaskName)

# Auto-fill Executable / WorkingDirectory when Task Type changes
$updateTaskType = {
    if ($rbCoreIssue.Checked) {
        $txtExe.Text = $TaskTypeMap["CoreIssue"].Executable
        $txtWorkDir.Text = $TaskTypeMap["CoreIssue"].WorkingDirectory
    }
    else {
        $txtExe.Text = $TaskTypeMap["CoreAuth"].Executable
        $txtWorkDir.Text = $TaskTypeMap["CoreAuth"].WorkingDirectory
    }
}
$rbCoreIssue.Add_CheckedChanged($updateTaskType)
$rbCoreAuth.Add_CheckedChanged($updateTaskType)

# ---- Group: Server Type and Range Selection ----
$grpServers = New-Object System.Windows.Forms.GroupBox
$grpServers.Text = "3. Server Type and Range Selection"
$grpServers.Location = New-Object System.Drawing.Point(10, 350)
$grpServers.Size = New-Object System.Drawing.Size(720, 210)
$Form.Controls.Add($grpServers)

$lblTypes = New-Object System.Windows.Forms.Label
$lblTypes.Text = "Server Types (include in discovery):"
$lblTypes.Location = New-Object System.Drawing.Point(10, 20)
$lblTypes.Size = New-Object System.Drawing.Size(250, 20)
$grpServers.Controls.Add($lblTypes)

$clbServerTypes = New-Object System.Windows.Forms.CheckedListBox
$clbServerTypes.Location = New-Object System.Drawing.Point(10, 40)
$clbServerTypes.Size = New-Object System.Drawing.Size(580, 60)
$clbServerTypes.CheckOnClick = $true
$clbServerTypes.MultiColumn = $true
$clbServerTypes.ColumnWidth = 90
foreach ($t in $ServerTypeList) {
    $clbServerTypes.Items.Add($t, $true) | Out-Null
}
$grpServers.Controls.Add($clbServerTypes)

$btnTypesSelectAll = New-Object System.Windows.Forms.Button
$btnTypesSelectAll.Text = "Select All"
$btnTypesSelectAll.Location = New-Object System.Drawing.Point(600, 40)
$btnTypesSelectAll.Size = New-Object System.Drawing.Size(110, 25)
$grpServers.Controls.Add($btnTypesSelectAll)

$btnTypesClearAll = New-Object System.Windows.Forms.Button
$btnTypesClearAll.Text = "Clear All"
$btnTypesClearAll.Location = New-Object System.Drawing.Point(600, 70)
$btnTypesClearAll.Size = New-Object System.Drawing.Size(110, 25)
$grpServers.Controls.Add($btnTypesClearAll)

# Servers are discovered in the background (via aws ec2 describe-instances) and kept in
# $Script:DiscoveredServers - no grid/list is rendered on the form.
$lblDiscoveredCount = New-Object System.Windows.Forms.Label
$lblDiscoveredCount.Text = "Servers discovered: 0"
$lblDiscoveredCount.Location = New-Object System.Drawing.Point(10, 110)
$lblDiscoveredCount.Size = New-Object System.Drawing.Size(400, 20)
$lblDiscoveredCount.Font = New-Object System.Drawing.Font($lblDiscoveredCount.Font, [System.Drawing.FontStyle]::Bold)
$grpServers.Controls.Add($lblDiscoveredCount)

$lblFrom = New-Object System.Windows.Forms.Label
$lblFrom.Text = "From #:"
$lblFrom.Location = New-Object System.Drawing.Point(10, 140)
$lblFrom.Size = New-Object System.Drawing.Size(50, 20)
$grpServers.Controls.Add($lblFrom)

$numFrom = New-Object System.Windows.Forms.NumericUpDown
$numFrom.Location = New-Object System.Drawing.Point(65, 138)
$numFrom.Size = New-Object System.Drawing.Size(60, 20)
$numFrom.Minimum = 0
$grpServers.Controls.Add($numFrom)

$lblTo = New-Object System.Windows.Forms.Label
$lblTo.Text = "To #:"
$lblTo.Location = New-Object System.Drawing.Point(140, 140)
$lblTo.Size = New-Object System.Drawing.Size(40, 20)
$grpServers.Controls.Add($lblTo)

$numTo = New-Object System.Windows.Forms.NumericUpDown
$numTo.Location = New-Object System.Drawing.Point(185, 138)
$numTo.Size = New-Object System.Drawing.Size(60, 20)
$numTo.Minimum = 0
$grpServers.Controls.Add($numTo)

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(260, 136)
$btnSelectAll.Size = New-Object System.Drawing.Size(110, 25)
$grpServers.Controls.Add($btnSelectAll)

$btnClearAll = New-Object System.Windows.Forms.Button
$btnClearAll.Text = "Clear All"
$btnClearAll.Location = New-Object System.Drawing.Point(380, 136)
$btnClearAll.Size = New-Object System.Drawing.Size(110, 25)
$grpServers.Controls.Add($btnClearAll)

$lblServerCount = New-Object System.Windows.Forms.Label
$lblServerCount.Text = "0 servers selected"
$lblServerCount.Location = New-Object System.Drawing.Point(10, 175)
$lblServerCount.Size = New-Object System.Drawing.Size(690, 20)
$grpServers.Controls.Add($lblServerCount)

# ---- Bottom buttons ----
$pnlButtons = New-Object System.Windows.Forms.Panel
$pnlButtons.Location = New-Object System.Drawing.Point(10, 570)
$pnlButtons.Size = New-Object System.Drawing.Size(720, 50)
$Form.Controls.Add($pnlButtons)

$btnExecute = New-Object System.Windows.Forms.Button
$btnExecute.Text = "Create Scheduled Task on Selected Servers"
$btnExecute.Location = New-Object System.Drawing.Point(0, 5)
$btnExecute.Size = New-Object System.Drawing.Size(360, 40)
$btnExecute.Font = New-Object System.Drawing.Font($btnExecute.Font, [System.Drawing.FontStyle]::Bold)
$btnExecute.BackColor = [System.Drawing.Color]::LightGreen
$pnlButtons.Controls.Add($btnExecute)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Close"
$btnClose.Location = New-Object System.Drawing.Point(590, 5)
$btnClose.Size = New-Object System.Drawing.Size(130, 40)
$pnlButtons.Controls.Add($btnClose)

#-----------------------------------------------------------------------------------------------
# STEP 3 - EVENT HANDLERS
#-----------------------------------------------------------------------------------------------

$btnTypesSelectAll.Add_Click({
    for ($i = 0; $i -lt $clbServerTypes.Items.Count; $i++) {
        $clbServerTypes.SetItemChecked($i, $true)
    }
})

$btnTypesClearAll.Add_Click({
    for ($i = 0; $i -lt $clbServerTypes.Items.Count; $i++) {
        $clbServerTypes.SetItemChecked($i, $false)
    }
})

$Script:NoSelection = $false

function Update-SelectedCountLabel {
    if (-not $Script:DiscoveredServers -or $Script:DiscoveredServers.Count -eq 0) {
        $lblServerCount.Text = "0 servers selected"
        return
    }
    if ($Script:NoSelection) {
        $lblServerCount.Text = "0 servers selected"
        return
    }
    $from = [int]$numFrom.Value
    $to = [int]$numTo.Value
    if ($from -gt $to) {
        $lblServerCount.Text = "0 servers selected (From # is greater than To #)"
    }
    else {
        $count = ($to - $from) + 1
        $lblServerCount.Text = "$count servers selected (index $from to $to)"
    }
}

function Clear-Discovery {
    $Script:DiscoveredServers = @()
    $Script:DiscoveredServerTypes = @()
    $Script:NoSelection = $false
    $numFrom.Maximum = 0
    $numTo.Maximum = 0
    $numFrom.Value = 0
    $numTo.Value = 0
    $lblDiscoveredCount.Text = "Servers discovered: 0"
    $lblServerCount.Text = "0 servers selected"
    $lblDiscoverStatus.Text = "Server type selection changed. Click 'Discover Servers' to refresh the list before creating a task."
    $lblDiscoverStatus.ForeColor = [System.Drawing.Color]::DarkOrange
}

$clbServerTypes.Add_ItemCheck({ Clear-Discovery })

$btnDiscover.Add_Click({
    if ($cmbPOD.SelectedIndex -lt 0) {
    [System.Windows.Forms.MessageBox]::Show("Please select a POD.", "POD Required", 'OK', 'Warning') | Out-Null
    return
}

    $SelectedServerTypes = @($clbServerTypes.CheckedItems)
    if (-not $SelectedServerTypes -or $SelectedServerTypes.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please check at least one Server Type before discovering servers.", "Server Type Required", 'OK', 'Warning') | Out-Null
        return
    }

    $AvailabilityZone = $cmbAZ.Text
    $SelectedPOD   = $cmbPOD.Text
    $SelectedStack = $cmbStack.Text
    $SelectedStackInitial = $SelectedStack.ToLower()[0]

    $Pod = $SelectedPOD.ToLower()
    $Pod = $cmbPOD.Text.ToLower()

    $lblDiscoverStatus.Text = "Discovering servers in the background... please wait."
    $lblDiscoverStatus.ForeColor = [System.Drawing.Color]::DarkOrange
    $Form.Refresh()

    $ServerList = @()

    foreach ($ServerType in $SelectedServerTypes) {
        $Raw = (aws ec2 describe-instances `
                --query "Reservations[*].Instances[*].{AvailabilityZone:Placement.AvailabilityZone,IpAddress:PrivateIpAddress,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" `
                --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='*$ServerType$ShortRegion$EnvironmentName$SelectedStackInitial*'" "Name=availability-zone,Values='$AvailabilityZone'" `
                --region $Region | ConvertFrom-Json)

        if ($Raw) {
            $ServerList += $Raw | Select-Object `
                @{n = "Name"; e = { $_.Name } }, `
                @{n = "AvailabilityZone"; e = { $_.AvailabilityZone } }, `
                @{n = "ServerType"; e = { $ServerType } }, `
                @{n = "UserId"; e = { Get-UserIdForServerType -ServerType $ServerType -Pod $Pod -EnvironmentName $EnvironmentName } }, `
                @{n = "ServerNumber"; e = {
    if ($_.Name -match '(\d+)$') {
        [int]$Matches[1]
    }
    else {
        0
    }
} }
        }
    }

    $Script:DiscoveredServers = @(
    $ServerList | Sort-Object -Property ServerType, ServerNumber
)
    $Script:DiscoveredServerTypes = @($SelectedServerTypes | Sort-Object)

    if (-not $Script:DiscoveredServers -or $Script:DiscoveredServers.Count -eq 0) {
        $lblDiscoverStatus.Text = "No servers found for the given criteria. Try a different Availability Zone."
        $lblDiscoverStatus.ForeColor = [System.Drawing.Color]::DarkRed
        $lblDiscoveredCount.Text = "Servers discovered: 0"
        return
    }

    $MinServer = ($Script:DiscoveredServers | Measure-Object ServerNumber -Minimum).Minimum
$MaxServer = ($Script:DiscoveredServers | Measure-Object ServerNumber -Maximum).Maximum

$numFrom.Minimum = $MinServer
$numFrom.Maximum = $MaxServer

$numTo.Minimum = $MinServer
$numTo.Maximum = $MaxServer

$numFrom.Value = $MinServer
$numTo.Value   = $MaxServer
    $Script:NoSelection = $false

    $lblDiscoveredCount.Text = "Servers discovered: $($Script:DiscoveredServers.Count)"
    $lblDiscoverStatus.Text = "$($Script:DiscoveredServers.Count) servers discovered. Use the From/To range below to select which ones to target."
    $lblDiscoverStatus.ForeColor = [System.Drawing.Color]::DarkGreen

    Update-SelectedCountLabel
})

$numFrom.Add_ValueChanged({ $Script:NoSelection = $false; Update-SelectedCountLabel })
$numTo.Add_ValueChanged({ $Script:NoSelection = $false; Update-SelectedCountLabel })

$btnSelectAll.Add_Click({
    if (-not $Script:DiscoveredServers -or $Script:DiscoveredServers.Count -eq 0) { return }
    $Script:NoSelection = $false
    $numFrom.Value = $numFrom.Minimum
    $numTo.Value = $numTo.Maximum
    Update-SelectedCountLabel
})

$btnClearAll.Add_Click({
    $Script:NoSelection = $true
    Update-SelectedCountLabel
})

$btnClose.Add_Click({ $Form.Close() })

$btnExecute.Add_Click({
    if (-not $Script:DiscoveredServers -or $Script:DiscoveredServers.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No servers discovered yet. Click 'Discover Servers' first.", "No Servers Discovered", 'OK', 'Warning') | Out-Null
        return
    }

    $CurrentCheckedTypes = @($clbServerTypes.CheckedItems | Sort-Object)
    if (@(Compare-Object $CurrentCheckedTypes $Script:DiscoveredServerTypes -SyncWindow 0).Count -ne 0) {
        [System.Windows.Forms.MessageBox]::Show("The checked Server Types no longer match the last discovery. Please click 'Discover Servers' again before creating the task.", "Discovery Out of Date", 'OK', 'Warning') | Out-Null
        return
    }

    $from = [int]$numFrom.Value
    $to = [int]$numTo.Value

    if ($Script:NoSelection -or $from -gt $to) {
        [System.Windows.Forms.MessageBox]::Show("No servers selected. Adjust the From/To range or click 'Select All'.", "No Servers Selected", 'OK', 'Warning') | Out-Null
        return
    }

    $SelectedServers = $Script:DiscoveredServers | Where-Object {
    $_.ServerNumber -ge $from -and
    $_.ServerNumber -le $to

}

    if (-not $SelectedServers -or $SelectedServers.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No servers selected. Adjust the From/To range or click 'Select All'.", "No Servers Selected", 'OK', 'Warning') | Out-Null
        return
    }

    $TaskType = if ($rbCoreIssue.Checked) { "CoreIssue" } else { "CoreAuth" }

$Executable = $txtExe.Text
$WorkingDirectory = $txtWorkDir.Text

# Get selected task name
$TaskName = $cmbTaskName.Text.Trim()

if ([string]::IsNullOrWhiteSpace($TaskName)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Please select a Task Name.",
        "Validation",
        "OK",
        "Warning"
    ) | Out-Null
    return
}

if (-not $TaskConfig.ContainsKey($TaskName)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Task '$TaskName' not found in TaskConfig.",
        "Validation",
        "OK",
        "Warning"
    ) | Out-Null
    return
}

$TaskInfo = $TaskConfig[$TaskName]

$TriggerID = $TaskInfo.TriggerID
$Port      = $TaskInfo.Port

# Build the argument automatically
$Argument = "$TriggerID $Port"

# Update textbox
$txtArg.Text = $Argument

    $TypeBreakdown = ($SelectedServers | Group-Object ServerType | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ", "

    $confirmMsg = "About to register scheduled task '$TaskName' on $($SelectedServers.Count) server(s).`n" +
                  "Server Type breakdown: $TypeBreakdown`n`n" +
                  "Task Type: $TaskType`nExecutable: $Executable`nArgument: $Argument`nWorkingDirectory: $WorkingDirectory`nTrigger: AtStartup`n`nProceed?"

    $confirm = [System.Windows.Forms.MessageBox]::Show($confirmMsg, "Confirm Task Creation", 'YesNo', 'Question')
    if ($confirm -ne 'Yes') { return }

    $option = New-PSSessionOption -ProxyAccessType NoProxyServer -OpenTimeout 20000
    $Results = @()
    # HTML Report
$DateTime = Get-Date -Format "yyyyMMdd_HHmmss"

$ReportFolder = "C:\Temp"
if (!(Test-Path $ReportFolder)) {
    New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null
}

$ReportFile = Join-Path $ReportFolder "Task_Create_Report_$DateTime.html"

$ReportData = @()


    foreach ($srv in $SelectedServers)
{
    $ComputerName = $srv.Name
    $UserId = $srv.UserId

    try
    {
        Invoke-Command -ComputerName $ComputerName `
            -SessionOption $option `
            -ErrorAction Stop `
            -ScriptBlock {

            param($Executable,$Argument,$WorkingDirectory,$UserId,$TaskName)

            $action = New-ScheduledTaskAction -Execute $Executable -Argument $Argument -WorkingDirectory $WorkingDirectory
            $trigger = New-ScheduledTaskTrigger -AtStartup
            $principal = New-ScheduledTaskPrincipal -UserId $UserId -LogonType Password -RunLevel Highest

            Register-ScheduledTask `
                -TaskName $TaskName `
                -Action $action `
                -Trigger $trigger `
                -Principal $principal `
                -Force | Out-Null

        } -ArgumentList $Executable,$Argument,$WorkingDirectory,$UserId,$TaskName

        $Status = "SUCCESS"
        $Message = "Task Created Successfully"

        $Results += "[OK] $ComputerName"

    }
    catch
    {
        $Status = "FAILED"
        $Message = $_.Exception.Message

        $Results += "[FAIL] $ComputerName -> $Message"
    }

    $ReportData += [PSCustomObject]@{
        "Server Name"       = $ComputerName
        "Task Name"         = $TaskName
        "Argument"          = $Argument
        "Executable"        = $Executable
        "Working Directory" = $WorkingDirectory
        "Status"            = $Status
        "Message"           = $Message
    }
}

# Generate HTML Report

$Style = @"
<style>
body{
    font-family:Segoe UI;
    font-size:10pt;
    margin:20px;
}
h2{
    color:#0078D7;
}
table{
    border-collapse:collapse;
    width:100%;
}
th{
    background-color:#0078D7;
    color:white;
    border:1px solid black;
    padding:6px;
}
td{
    border:1px solid black;
    padding:6px;
}
</style>
"@

$Header = @"
<h2>Scheduled Task Creation Report</h2>

<table>
<tr><td><b>Date</b></td><td>$(Get-Date)</td></tr>
<tr><td><b>Task Name</b></td><td>$TaskName</td></tr>
<tr><td><b>Executable</b></td><td>$Executable</td></tr>
<tr><td><b>Argument</b></td><td>$Argument</td></tr>
<tr><td><b>Working Directory</b></td><td>$WorkingDirectory</td></tr>
<tr><td><b>Total Servers</b></td><td>$($SelectedServers.Count)</td></tr>
</table>

<br/>
"@

$ReportData |
ConvertTo-Html `
    -Head $Style `
    -PreContent $Header |
Out-File $ReportFile -Encoding UTF8

Invoke-Item $ReportFile

[System.Windows.Forms.MessageBox]::Show(
    "Task creation completed successfully.`r`n`r`nReport saved to:`r`n$ReportFile",
    "Task Creation Complete",
    "OK",
    "Information"
) | Out-Null
})

#-----------------------------------------------------------------------------------------------
# STEP 4 - SHOW FORM
#-----------------------------------------------------------------------------------------------

$Form.AutoScrollMinSize = New-Object System.Drawing.Size(740, 630)

[void]$Form.ShowDialog()
