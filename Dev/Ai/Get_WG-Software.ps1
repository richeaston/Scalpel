# 1. Set Encoding to handle special characters correctly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 2. Optimized Exclusion Patterns (Compiled Regex is faster than looping)
# We join the patterns with '|' to create a single "OR" regex match.
$exclusionList = @(
    'Intel', 'App Installer', 'Realtek', 'SAPIEN', 
    'ARP\\Machine.*X64.*Steam App', 'Microsoft.Edge', 
    'MSIX.*Microsoft.MicrosoftEdge.Stable', 'Windows', 'UI.Xaml', 
    'Microsoft.DotNet.DesktopRuntime.8', 'Microsoft Engagement Framework', 
    'Store Experience Host', 'Sticky Notes', 'store', '.Net Native', 
    'Image Extension', 'Video Extension', 'Media Extension', 
    'Microsoft Visual C\+\+', 'Microsoft.UI.Xaml.2', 'Nvidia', 
    'paint', 'runtime', 'Phone', 'snipping tool', 'Context Menu'
)
# Create a case-insensitive Regex string (e.g., "Intel|Realtek|...")
$exclusionRegex = ($exclusionList | ForEach-Object { [Regex]::Escape($_).Replace('\*', '.*') }) -join '|'

Write-Host "Gathering Winget packages..." -ForegroundColor Cyan

# 3. Capture and Filter Winget Output
# We run winget and immediately filter lines using the regex.
$wingetRaw = winget list --source Winget
$validLines = $wingetRaw | Where-Object {
    ($_ -notmatch $exclusionRegex) -and 
    ($_ -notmatch "^Name\s+Id\s+Version") -and 
    ($_ -notmatch "^-+$") -and 
    (![string]::IsNullOrWhiteSpace($_))
}

# 4. Parse Lines (Refactored for Speed)
# instead of "$parsedApps +=", we assign the result of the loop to the variable.
$parsedApps = foreach ($line in $validLines) {
    $name = $null; $id = $null; $version = $null; $available = $null; $source = $null

    # Logic A: Handle ARP (Add/Remove Programs) paths
    $arpIndex = $line.IndexOf("ARP\Machine\")
    
    if ($arpIndex -ge 0) {
        $name = $line.Substring(0, $arpIndex).Trim()
        $remaining = $line.Substring($arpIndex)
        
        if ($remaining -match "^(.+?)\s+([^\s]+)\s+([^\s]+)\s*([^\s]+)?$") {
            $id = $Matches[2]
            $version = $Matches[3].Trim()
            $available = if ($Matches[4]) { $Matches[4].Trim() } else { $version }
        }
    } 
    # Logic B: Standard Winget output columns
    elseif ($line -match "^(.+?)\s+([^\s]+)\s+([^\s]+)\s*([^\s]+)?$") {
        # Validations to ensure we captured real columns
        if ($Matches[1] -and $Matches[2] -ne "/") {
            $name = $Matches[1].Trim()
            $id   = $Matches[2].Trim()
            $version = $Matches[3].Trim()
            $available = if ($Matches[4]) { $Matches[4].Trim() } else { $version }
        }
    }

    # Only output object if parsing succeeded and data is valid (no '%' placeholders)
    if ($id -and $version -notmatch "%" -and $available -notmatch "%") {
        # Determine Source based on ID pattern
        $source = if ($id -like '*MSIX*') { "msstore" } else { "winget" }
        
        [PSCustomObject]@{
            Name      = $name
            Id        = $id
            Version   = $version
            Available = $available
            Source    = $source
        }
    }
}

# 5. Apply Overrides
$overrides = @{
    "EarTrumpet"                  = @{ Id = "File-New-Project.EarTrumpet"; Source = "winget" }
    "Messenger"                   = @{ Id = "9WZDNCRF0083"; Source = "msstore" }
    "Stardock Start11"            = @{ Id = "Stardock.Start11.v2"; Source = "winget" }
    "SignalRGB"                   = @{ Id = "WhirlwindFX.SignalRgb"; Source = "winget" }
    "Spotify - Music and Podcasts" = @{ Id = "9NCBCSZSJRSB"; Source = "msstore" }
    "Whatsapp"                    = @{ Id = "9NKSQGP7F2NH"; Source = "msstore" }
}

foreach ($app in $parsedApps) {
    if ($overrides.ContainsKey($app.Name)) {
        $app.Id     = $overrides[$app.Name].Id
        $app.Source = $overrides[$app.Name].Source
    }
}

# 6. Deduplication Strategy
# Prefer 'winget' source over 'msstore' if duplicates exist
$uniqueApps = $parsedApps | Group-Object Name | ForEach-Object {
    $group = $_.Group
    if ($group.Count -gt 1) {
        # If multiple, try to find the winget one, otherwise take the first one
        ($group | Where-Object Source -eq 'winget' | Select-Object -First 1) ?? ($group | Select-Object -First 1)
    } else {
        $group[0]
    }
}

# Show the table
$uniqueApps | Sort-Object Name | Format-Table -AutoSize

# 7. Upgrade Logic
Write-Host "`nChecking for newer versions..." -BackgroundColor Green -ForegroundColor Yellow

foreach ($app in ($uniqueApps | Sort-Object Name)) {
    # Check: If 'Available' is not empty AND it is different from 'Version'
    if (![string]::IsNullOrWhiteSpace($app.Available) -and ($app.Available -ne $app.Version)) {
        
        Write-Host "Upgrade found for " -NoNewline -ForegroundColor Green
        Write-Host "$($app.Name) " -NoNewline -ForegroundColor Yellow
        Write-Host "($($app.Version) -> $($app.Available)). Installing..." -ForegroundColor Green
        
        # Run upgrade
        winget upgrade --id $app.Id --silent --accept-package-agreements --accept-source-agreements --source $app.Source
        Write-Host ""
    } else {
        Write-Host "Latest version of " -NoNewline
        Write-Host "$($app.Name) " -NoNewline -ForegroundColor Yellow
        Write-Host "is already installed."
    }
}

# 8. Export to JSON
$outputFile = Join-Path -Path ($PSScriptRoot ?? $PWD.Path) -ChildPath "winget_apps.json"
$uniqueApps | Sort-Object Name | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 -FilePath $outputFile -Force

Write-Host "`nData exported to $outputFile" -BackgroundColor Blue -ForegroundColor Yellow
Write-Host ""
