# Replace with the actual path to the server names text file
$serversFile = "D:\RajaK\Collect_Traces\servers.txt" 
# Replace with the actual destination path
$destinationPath = "D:\RajaK\Collect_Traces"
$startTime = [DateTime]::ParseExact("07-18-2023 03:15:45", "MM-dd-yyyy HH:mm:ss", $null)
$endTime = [DateTime]::ParseExact("07-22-2023 16:44:42", "MM-dd-yyyy HH:mm:ss", $null)

 
############################################################################################
# Read the server names from the text file
$servers = Get-Content -Path $serversFile

foreach ($server in $servers) {

Write-Host "Copying the files from '$server' Server "

    # Replace with the actual folder path
    $folderPath = "\\$server\d$\TraceFiles\CoreAuth"
    $serverFolder = Join-Path -Path $destinationPath -ChildPath $server
    
    # Create a folder for the server if it doesn't exist
    if (!(Test-Path -Path $serverFolder)) {
        New-Item -ItemType Directory -Path $serverFolder | Out-Null
    }
    
    $files = Get-ChildItem -Path $folderPath -File | Where-Object {
        $_.Name -like "$server*_wfCommonAuthScaleSource_*"
    }
    
    foreach ($file in $files) {
        $contentFound = $false
        $matchingLines = @()

        $fileContent = Get-Content -Path $file.FullName

        foreach ($line in $fileContent) {
            if ($line -match "\d{2}/\d{2}/\d{4} \d{1,2}:\d{2}:\d{2}\.\d{1,3}") {
                $timestamp = [DateTime]::ParseExact($matches[0], "MM/dd/yyyy HH:mm:ss.fff", $null)
                if ($timestamp -ge $startTime -and $timestamp -le $endTime) {
                    $contentFound = $true
                    $matchingLines += $line
                    # Break the loop once content is found within the time period
                    break
                }
            }
        }
        

        if ($contentFound) {
           # Write-Host "Content found within the period from '$startTime' to '$endTime' in file '$($file.Name)':"
            foreach ($line in $matchingLines) {
                #Write-Host $line
            }
            
            $destinationFile = Join-Path -Path $serverFolder -ChildPath $file.Name
            Copy-Item -Path $file.FullName -Destination $destinationFile -Force
            #Write-Host "File copied to '$destinationFile'."
        } else {
           # Write-Host "No content found within the period from '$startTime' to '$endTime' in file '$($file.Name)'."
        }
    }
}