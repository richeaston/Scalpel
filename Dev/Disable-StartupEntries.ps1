# Get entries from the Run keys
$RunHKLM = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$RunHKCU = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

# Get entries from the Startup folders (for the current user)
$StartupFolder = [Environment]::GetFolderPath("Startup")
$StartupItems = Get-ChildItem $StartupFolder | Where-Object {$_.Extension -in ".lnk", ".exe", ".bat", ".cmd", ".vbs", ".js"} | ForEach-Object {$_.Name}

# Combine and process the entries
$StartupEntries = @()

if ($RunHKLM) {
    foreach ($property in $RunHKLM.PSObject.Properties) {
        if ($property.Value -ne $null -and !$property.Name.StartsWith("PS")) {
            $StartupEntries += $property.Name
        }
    }
}

if ($RunHKCU) {
    foreach ($property in $RunHKCU.PSObject.Properties) {
        if ($property.Value -ne $null -and !$property.Name.StartsWith("PS")) {
            $StartupEntries += $property.Name
        }
    }
}

if ($StartupItems) { $StartupEntries += $StartupItems }

# Process and ask to disable
foreach ($entry in $StartupEntries | Sort-Object -Unique) {
    $response = Read-Host "Disable '$entry'? (Y/N)"

    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "`tDisabling '$entry'..."

        # Disable based on where the entry is (Registry or Startup Folder)
        if ($RunHKLM.PSObject.Properties.Where({$_.Name -eq $entry})) {  # Corrected check for HKLM
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name $entry -Force -ErrorAction SilentlyContinue
        } elseif ($RunHKCU.PSObject.Properties.Where({$_.Name -eq $entry})) { # Corrected check for HKCU
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name $entry -Force -ErrorAction SilentlyContinue
        } elseif (Get-ChildItem $StartupFolder | Where-Object {$_.Name -eq $entry}) {
           $itemToRemove = Join-Path $StartupFolder $entry
           Remove-Item $itemToRemove -Force -ErrorAction SilentlyContinue
        }

        Write-Host "`t'$entry' disabled." -ForegroundColor Red
    } else {
        Write-Host "`t'$entry' left enabled." -ForegroundColor Green
    }
}
write-host
Write-Host "Finished processing startup entries." -BackgroundColor Green -ForegroundColor Yellow