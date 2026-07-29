######################################################################################################################
# Professional File Copy Tool (GUI)  |  DEVELOPED BY:: Mahendra Dwivedi
# Version 1.0 | GUI Release | Date:: 27-July-2026
######################################################################################################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

#-------------------------------------------------------
# Main Form
#-------------------------------------------------------

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Professional File Copy Tool By Mahendra Dwivedi"
$Form.Size = New-Object System.Drawing.Size(850,650)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.BackColor = [System.Drawing.Color]::WhiteSmoke

#-------------------------------------------------------
# Title
#-------------------------------------------------------

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Professional File Copy Tool"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object Drawing.Point(20,15)
$Form.Controls.Add($lblTitle)

#-------------------------------------------------------
# Source
#-------------------------------------------------------

$lblSource = New-Object System.Windows.Forms.Label
$lblSource.Text = "Source Folder"
$lblSource.Location = New-Object Drawing.Point(20,70)
$lblSource.AutoSize = $true
$Form.Controls.Add($lblSource)

$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.Location = New-Object Drawing.Point(20,95)
$txtSource.Size = New-Object Drawing.Size(650,28)
$Form.Controls.Add($txtSource)

$btnSource = New-Object System.Windows.Forms.Button
$btnSource.Text = "Browse..."
$btnSource.Location = New-Object Drawing.Point(690,93)
$btnSource.Size = New-Object Drawing.Size(110,30)
$Form.Controls.Add($btnSource)

#-------------------------------------------------------
# Destination
#-------------------------------------------------------

$lblDestination = New-Object System.Windows.Forms.Label
$lblDestination.Text = "Destination Folder"
$lblDestination.Location = New-Object Drawing.Point(20,140)
$lblDestination.AutoSize = $true
$Form.Controls.Add($lblDestination)

$txtDestination = New-Object System.Windows.Forms.TextBox
$txtDestination.Location = New-Object Drawing.Point(20,165)
$txtDestination.Size = New-Object Drawing.Size(650,28)
$Form.Controls.Add($txtDestination)

$btnDestination = New-Object System.Windows.Forms.Button
$btnDestination.Text = "Browse..."
$btnDestination.Location = New-Object Drawing.Point(690,163)
$btnDestination.Size = New-Object Drawing.Size(110,30)
$Form.Controls.Add($btnDestination)

#-------------------------------------------------------
# Copy Mode Group
#-------------------------------------------------------

$grpMode = New-Object System.Windows.Forms.GroupBox
$grpMode.Text = "Copy Mode"
$grpMode.Location = New-Object Drawing.Point(20,220)
$grpMode.Size = New-Object Drawing.Size(780,90)
$Form.Controls.Add($grpMode)

$rbFirst = New-Object System.Windows.Forms.RadioButton
$rbFirst.Text = "First Time Copy"
$rbFirst.Location = New-Object Drawing.Point(20,35)
$rbFirst.AutoSize = $true
$rbFirst.Checked = $true
$grpMode.Controls.Add($rbFirst)

$rbOverwrite = New-Object System.Windows.Forms.RadioButton
$rbOverwrite.Text = "Overwrite Copy"
$rbOverwrite.Location = New-Object Drawing.Point(220,35)
$rbOverwrite.AutoSize = $true
$grpMode.Controls.Add($rbOverwrite)

$rbModified = New-Object System.Windows.Forms.RadioButton
$rbModified.Text = "Only Modified Copy"
$rbModified.Location = New-Object Drawing.Point(430,35)
$rbModified.AutoSize = $true
$grpMode.Controls.Add($rbModified)

#-------------------------------------------------------
# Buttons
#-------------------------------------------------------

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Copy"
$btnStart.Size = New-Object Drawing.Size(130,40)
$btnStart.Location = New-Object Drawing.Point(220,330)
$btnStart.BackColor = [System.Drawing.Color]::LightGreen
$Form.Controls.Add($btnStart)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object Drawing.Size(130,40)
$btnCancel.Location = New-Object Drawing.Point(380,330)
$btnCancel.Enabled = $false
$Form.Controls.Add($btnCancel)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Size = New-Object Drawing.Size(130,40)
$btnExit.Location = New-Object Drawing.Point(540,330)
$Form.Controls.Add($btnExit)

#-------------------------------------------------------
# Progress
#-------------------------------------------------------

$lblProgress = New-Object System.Windows.Forms.Label
$lblProgress.Text = "Progress"
$lblProgress.Location = New-Object Drawing.Point(20,390)
$lblProgress.AutoSize = $true
$Form.Controls.Add($lblProgress)

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object Drawing.Point(20,415)
$ProgressBar.Size = New-Object Drawing.Size(780,25)
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = 100
$Form.Controls.Add($ProgressBar)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Waiting..."
$lblStatus.Location = New-Object Drawing.Point(20,450)
$lblStatus.AutoSize = $true
$Form.Controls.Add($lblStatus)

#-------------------------------------------------------
# Statistics Group
#-------------------------------------------------------

$grpStats = New-Object System.Windows.Forms.GroupBox
$grpStats.Text = "Statistics"
$grpStats.Location = New-Object Drawing.Point(20,480)
$grpStats.Size = New-Object Drawing.Size(780,120)
$Form.Controls.Add($grpStats)

$labels = @(
"Total Files",
"Copied",
"Skipped",
"Failed",
"Folders",
"Elapsed"
)

$Y = 30

foreach($Text in $labels)
{
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "$Text :"
    $lbl.Location = New-Object Drawing.Point(20,$Y)
    $lbl.AutoSize = $true
    $grpStats.Controls.Add($lbl)

    $Value = New-Object System.Windows.Forms.Label
    $Value.Text = "0"
    $Value.Location = New-Object Drawing.Point(120,$Y)
    $Value.AutoSize = $true
    $Value.Name = $Text.Replace(" ","")
    $grpStats.Controls.Add($Value)

    if($Y -eq 30)
    {
        $Y = 60
    }
    else
    {
        $Y += 30
    }
}

#-------------------------------------------------------
# Folder Browser
#-------------------------------------------------------

$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

$btnSource.Add_Click({

    if($FolderBrowser.ShowDialog() -eq "OK")
    {
        $txtSource.Text = $FolderBrowser.SelectedPath
    }

})

$btnDestination.Add_Click({

    if($FolderBrowser.ShowDialog() -eq "OK")
    {
        $txtDestination.Text = $FolderBrowser.SelectedPath
    }

})

#-------------------------------------------------------
# Exit Button
#-------------------------------------------------------

$btnExit.Add_Click({

    $Form.Close()

})

#part 2
#==========================================================
# Global Variables
#==========================================================

$script:CancelCopy = $false
$script:Copied = 0
$script:Skipped = 0
$script:Failed = 0

#==========================================================
# Update Statistics
#==========================================================

function Update-Statistics
{
    param(
        $TotalFiles,
        $Copied,
        $Skipped,
        $Failed,
        $Folders
    )

    ($grpStats.Controls | Where-Object Name -eq "TotalFiles").Text = $TotalFiles
    ($grpStats.Controls | Where-Object Name -eq "Copied").Text = $Copied
    ($grpStats.Controls | Where-Object Name -eq "Skipped").Text = $Skipped
    ($grpStats.Controls | Where-Object Name -eq "Failed").Text = $Failed
    ($grpStats.Controls | Where-Object Name -eq "Folders").Text = $Folders

    $Form.Refresh()
}

#==========================================================
# Copy Function
#==========================================================

function Start-CopyProcess
{
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Mode
    )

    $script:Copied = 0
    $script:Skipped = 0
    $script:Failed = 0
    $script:CancelCopy = $false

    if (!(Test-Path $Destination))
    {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    $Files = Get-ChildItem $Source -File -Recurse
    $Folders = (Get-ChildItem $Source -Directory -Recurse).Count
    $TotalFiles = $Files.Count

    Update-Statistics $TotalFiles 0 0 0 $Folders

    $ProgressBar.Value = 0

    $Count = 0

    foreach($File in $Files)
    {

        if($script:CancelCopy)
        {
            break
        }

        $Count++

        $Relative = $File.FullName.Substring($Source.Length)

        $DestFile = Join-Path $Destination $Relative

        $DestFolder = Split-Path $DestFile

        if(!(Test-Path $DestFolder))
        {
            New-Item -ItemType Directory -Path $DestFolder -Force | Out-Null
        }

        try
        {

            switch($Mode)
            {

                "First"
                {

                    if(!(Test-Path $DestFile))
                    {
                        Copy-Item $File.FullName $DestFile
                        $script:Copied++
                    }
                    else
                    {
                        $script:Skipped++
                    }

                }

                "Overwrite"
                {

                    Copy-Item $File.FullName $DestFile -Force
                    $script:Copied++

                }

                "Modified"
                {

                    if(!(Test-Path $DestFile))
                    {

                        Copy-Item $File.FullName $DestFile
                        $script:Copied++

                    }
                    else
                    {

                        $DestInfo = Get-Item $DestFile

                        if($File.LastWriteTime -gt $DestInfo.LastWriteTime)
                        {

                            Copy-Item $File.FullName $DestFile -Force
                            $script:Copied++

                        }
                        else
                        {
                            $script:Skipped++
                        }

                    }

                }

            }

        }
        catch
        {

            $script:Failed++

        }

        $Percent = [math]::Round(($Count/$TotalFiles)*100)

        if($Percent -gt 100)
        {
            $Percent = 100
        }

        $ProgressBar.Value = $Percent

        $lblStatus.Text = "Copying $Count of $TotalFiles : $($File.Name)"

        Update-Statistics `
            $TotalFiles `
            $script:Copied `
            $script:Skipped `
            $script:Failed `
            $Folders

        [System.Windows.Forms.Application]::DoEvents()

    }

    $ProgressBar.Value = 100

    if($script:CancelCopy)
    {
        $lblStatus.Text = "Copy Cancelled"
    }
    else
    {
        $lblStatus.Text = "Copy Completed Successfully"
    }

}

#==========================================================
# Cancel Button
#==========================================================

$btnCancel.Add_Click({

    $script:CancelCopy = $true

})

#==========================================================
# Start Button
#==========================================================

$btnStart.Add_Click({

    if(!(Test-Path $txtSource.Text))
    {
        [System.Windows.Forms.MessageBox]::Show("Source folder does not exist.")
        return
    }

    if([string]::IsNullOrWhiteSpace($txtDestination.Text))
    {
        [System.Windows.Forms.MessageBox]::Show("Select Destination Folder.")
        return
    }

    $btnStart.Enabled = $false
    $btnCancel.Enabled = $true

    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

    if($rbFirst.Checked)
    {
        Start-CopyProcess `
            -Source $txtSource.Text `
            -Destination $txtDestination.Text `
            -Mode "First"
    }

    elseif($rbOverwrite.Checked)
    {
        Start-CopyProcess `
            -Source $txtSource.Text `
            -Destination $txtDestination.Text `
            -Mode "Overwrite"
    }

    elseif($rbModified.Checked)
    {
        Start-CopyProcess `
            -Source $txtSource.Text `
            -Destination $txtDestination.Text `
            -Mode "Modified"
    }

    $StopWatch.Stop()

    ($grpStats.Controls | Where-Object Name -eq "Elapsed").Text = $StopWatch.Elapsed.ToString()

    $btnStart.Enabled = $true
    $btnCancel.Enabled = $false

    [System.Windows.Forms.MessageBox]::Show(
        "Operation Completed.`n`nCopied : $script:Copied`nSkipped : $script:Skipped`nFailed : $script:Failed",
        "Completed",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

})

#-------------------------------------------------------
# Run
#-------------------------------------------------------

[void]$Form.ShowDialog()