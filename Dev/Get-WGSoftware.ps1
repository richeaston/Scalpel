$patterns = @(
    '*Intel*'
    '*Realtek*'
    '*SAPIEN*'
    '*ARP*Machine*X64*Steam App*'
    '*Microsoft.Edge*'
    '*Windows*'
    '*UI.Xaml*'
    '*Microsoft.DotNet.DesktopRuntime.8*'
    '*Microsoft Engagement Framework*'
    '*Store Experience Host*'
    '*Sticky Notes*'
    '*store*'
    '*.Net Native*'
    '*Image Extension*'
    '*Video Extension*'
    '*Media Extension*'
    '*Microsoft Visual C++*'
    'Microsoft.UI.Xaml.2.*'
    '*paint*'
    '*runtime*'
    '*Phone*'
    '*snipping tool*'
    '*Context Menu*'
)

$wingetpackages = winget list --source Winget | Where-Object {
    foreach ($pattern in $patterns) {
        if ($_ -like $pattern) { return $false } # Match found, exclude line
    }
    return $true # No match found, include line
}


$validLines = $wingetpackages | Where-Object {
    $_ -notmatch "^Name\s+Id\s+Version\s+Available" -and
    $_ -notmatch "^-+$" -and
    $_.Trim() -ne ""
}

$parsedApps = @()
foreach ($line in $validLines) {
    $arpIndex = $line.IndexOf("ARP\Machine\")

    if ($arpIndex -ge 0) {
        # ARP\ found
        # Extract Name (before ARP\)
        $name = $line.Substring(0, $arpIndex).Trim()

        # Extract ID, Version, and Available (starting at ARP\Machine\)
        $remaining = $line.Substring($arpIndex) 

        if ($remaining -match "^(.+?)\s+([^\s]+)\s+([^\s]+)\s*([^\s]+)?$") {
            if ($null -ne $remaining -and $remaining -ne "") {
                if ($remaining -notcontains '%') {
                    $id = $Matches[2]  # ID is the FIRST captured group (including ARP\Machine\)
                    $version = $Matches[3].Trim()
                    $available = if ($Matches[4]) { $Matches[4].Trim() } else { $Matches[3].Trim() }
                    $parsedApps += [PSCustomObject]@{
                        Name      = $name
                        Id        = $id
                        Version   = $version
                        Available = $available
                        Source    = if ($Matches[2] -like '*MSIX*') { "mstore" } else { "winget" }
                    }
                }
            }
        }
        else {
            #Write-Host "Error parsing line (ARP case): $line" # Debugging
        }
    }
    else {
        # ARP\ not found - use original method (with improvements)
        if ($line -match "^(.+?)\s+([^\s]+)\s+([^\s]+)\s*([^\s]+)?$") {
            if ($null -ne $Matches[1] -and $Matches[1] -ne "" -and $version -notlike '*%*' -and $Matches[2] -ne "/") {
                $parsedApps += [PSCustomObject]@{
                    Name      = $Matches[1].Trim()
                    Id        = $Matches[2].Trim()
                    Version   = $Matches[3].Trim()
                    Available = if ($Matches[4]) { $Matches[4].Trim() } else { $Matches[3].Trim() }
                    Source    = if ($Matches[2] -like '*MSIX*') { "mstore" } else { "winget" }
                
                }
            }
        }
    }
    
}

# Remove special characters from the parsed data
foreach ($app in $parsedApps) {
    $app.Name = $app.Name -replace "[^ -~]+", "" 
    $app.Id = $app.Id -replace "[^ -~]+", ""
    $app.Version = $app.Version -replace "[^ -~]+", ""
    $app.Available = $app.Available -replace "[^ -~]+", ""
    $app.Source = $app.source -replace "[^ -~]+", ""
}

$parsedApps | Sort-Object Name | Format-Table -AutoSize

Write-host " Installing any newer versions, Please Wait... " -BackgroundColor Green -ForegroundColor Yellow
Write-host ""
foreach ($app in ($parsedApps | Sort-Object Name)) {
    if ($($app.available) -gt $($app.version)) {
        Write-host "Upgrade version for " -NoNewline -ForegroundColor Green
        Write-host $($app.name) -NoNewline -ForegroundColor Yellow
        Write-Host ", Installing." -ForegroundColor Green
        Write-host ""
        winget upgrade --id $($app.id) --silent --accept-package-agreements --accept-source-agreements --source $app.Source 
        Write-host ""
    }
    else {
        Write-host "Latest version of " -NoNewline
        Write-host $($app.name) -NoNewline -ForegroundColor Yellow
        Write-Host " is already installed."
    }
}

# Export to JSON
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$parsedApps | sort-object Name | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 -FilePath "$dir\winget_apps.json"

Write-Host "`n Data exported to winget_apps.json " -BackgroundColor Blue -ForegroundColor Yellow
Write-host ""