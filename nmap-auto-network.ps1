# Created By: Jake Nutt & ChatGPT

# Prompt the user for the year and quarter
$year = Read-Host "Enter the year"
$quarter = Read-Host "Enter the quarter (e.g., Q1, Q2, Q3, Q4)"

# Preconfigured source and destination directories
$sourceDir = "C:\scans"  # Change this path to your source directory on finished nmap scans
$destinationDir = "C:\WebMap\XML"  # Change this path to your destination directory for scans to be reviewed by WebMap

# Define the NICs and their corresponding nmap commands
$nics = @(
    @{ Name = "Network1"; NmapCommand = 'nmap -sS -p- -T4 -vv -iL "C:\nmap-targetfiles\network-101.txt" -oX "C:\scans\Year_Quarter_scanvLan101.xml" --max-retries 0 --open --webxml --excludefile "C:\nmap-targetfiles\Targets-Exclude.txt"' },
    @{ Name = "Network2"; NmapCommand = 'nmap -sS -p- -T4 -vv -iL "C:\nmap-targetfiles\network-102.txt" -oX "C:\scans\Year_Quarter_scanvLan102.xml" --max-retries 0 --open --webxml --excludefile "C:\nmap-targetfiles\Targets-Exclude.txt"' },
    # Add more NICs and commands as needed
    @{ Name = "Network3"; NmapCommand = 'nmap -sS -p- -T4 -vv -iL "C:\nmap-targetfiles\network-103.txt" -oX "C:\scans\Year_Quarter_scanvLan103.xml" --max-retries 0 --open --webxml --excludefile "C:\nmap-targetfiles\Targets-Exclude.txt"' }
)

function Run-Nmap {
    param (
        [string]$command
    )
    Write-Host "Running nmap command: $command"
    Start-Process -FilePath "nmap" -ArgumentList $command -Wait
}

function Disable-NIC {
    param (
        [string]$nicName
    )
    Write-Host "Disabling NIC: $nicName"
    Get-NetAdapter -Name $nicName | Disable-NetAdapter -Confirm:$false
}

function Enable-NIC {
    param (
        [string]$nicName
    )
    Write-Host "Enabling NIC: $nicName"
    Get-NetAdapter -Name $nicName | Enable-NetAdapter -Confirm:$false
}

function Move-FileToArchive {
    param (
        [System.IO.FileInfo]$file,
        [string]$archiveDir
    )													 
    Write-Host "Moving file $($file.FullName) to $archiveDir"
    Move-Item -Path $file.FullName -Destination $archiveDir -Force																	   
}

function Copy-OutputFiles {
    param (
        [string]$sourceDir,
        [string]$destinationDir
    )
    Write-Host "Copying output files from $sourceDir to $destinationDir"
    Get-ChildItem -Path $sourceDir -Filter "*.xml" | Copy-Item -Destination $destinationDir -Force
}

# Disable all NICs before starting
foreach ($nic in $nics) {
    Disable-NIC -nicName $nic.Name
}

# Handle stopping the script gracefully
$script:stopped = $false
Register-EngineEvent PowerShell.Exiting -Action {
    $script:stopped = $true
}

try {
    foreach ($nic in $nics) {
        $nicName = $nic.Name
        $nmapCommand = $nic.NmapCommand

        # Replace placeholders with actual year and quarter
        $nmapCommand = $nmapCommand -replace "Year", $year -replace "Quarter", $quarter

        # Enable the current NIC and wait for 10 seconds
        Enable-NIC -nicName $nicName
        Start-Sleep -Seconds 10

        # Run the associated nmap command
        Run-Nmap -command $nmapCommand

        # Disable the current NIC if it is not the last NIC in the list
        if ($nic -ne $nics[-1]) {
            Disable-NIC -nicName $nicName
        }

        if ($script:stopped) {
            break
        }
    }
} finally {
    # Ensure the current NIC is disabled and the last NIC is enabled
    if ($nicName) {
        Disable-NIC -nicName $nicName
    }
    Enable-NIC -nicName $nics[-1].Name

    # Create the archive directory based on the first 7 characters of the first file
    $filesToMove = Get-ChildItem -Path $destinationDir -Filter "*.xml"
    if ($filesToMove.Count -gt 0) {
        $firstFile = $filesToMove[0]
        $yearQuarter = $firstFile.Name.Substring(0, 7)
        $archiveDir = Join-Path -Path $destinationDir -ChildPath $yearQuarter
        Write-Host "Creating archive directory: $archiveDir"
        if (-not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir | Out-Null
        }

        # Move existing files to the archive directory
        foreach ($file in $filesToMove) {
            Move-FileToArchive -file $file -archiveDir $archiveDir
        }
    }

    # Copy the new output files to the destination directory
    Copy-OutputFiles -sourceDir $sourceDir -destinationDir $destinationDir

    Write-Host "Script execution completed. Output files copied to $destinationDir."
}
