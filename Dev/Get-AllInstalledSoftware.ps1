Function Get-installedsoftware 
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$name,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$exclusions
    )
    $paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
    
    $installedSoftware = foreach ($p in $paths)
    {
        if ($name)
        {
            $installed = Get-ItemProperty "$p\*" | Where-Object { $_.DisplayName -like $name } | Select-Object * | sort-object DisplayName
        #   $installed = Get-ItemProperty "$p\*" | Where-Object { $_.DisplayName -like $name } | Select-Object DisplayName, DisplayVersion, UninstallString, SystemComponent | sort-object DisplayName
        }
        foreach ($exclusion in $exclusions)
        {
            $installed = $installed | Where-Object { $_.DisplayName -notlike $exclusion }
        }
        
        $sassets = @()
        foreach ($i in $installed)
        {
            $item = [pscustomobject]@{
                Name = $i.Displayname
                Version = $i.DisplayVersion
                Uninstall = $i.UninstallString
                Hive = $p
                SystemComponent = $i.SystemComponent
            }
            if ($null -ne $item.name)
            {
                $sassets += $item
            }
        }
        #detect software installs
        $sassets #| Sort-Object Name | Format-Table -AutoSize -Wrap
    }
    return $installedSoftware
}

function Get-LocalApplications
{
    
    $tempapplist = "c:\temp\appslist.json"
    $wingetPackages = winget export -o $tempapplist --include-versions --accept-source-agreements
    $appsData = Get-Content -Path $tempapplist | ConvertFrom-Json
    $apparray = @()
    
    # Iterate through each source in the JSON
    foreach ($source in $appsData.Sources)
    {
        foreach ($package in $source.Packages)
        {
            $apparray += $package
        }
    }
    
    $parsedApps = @()
    foreach ($app in $apparray)
    {
        $appsearch = winget search $app.PackageIdentifier
        
        # Skip header lines and empty lines
        $validLines = $appsearch | Where-Object {
            $_ -notmatch "^Name\s*Id\s*Version\s*Source" -and
            $_ -notmatch "^-+$" -and
            $_.Trim() -ne ""
        }
        
        foreach ($line in $validLines)
        {
            # Regex to capture the entire name, even with multiple words
            if ($line -match '^((?:\S+\s+)+?)(\S+)\s+(\S+)\s+(\S+)$' -and $line -notlike '*Alpha*' -and $line -notlike '*Beta*' -and $line -notlike '*Preview*' -and $line -notlike '*Canary*' -and $line -notlike '*Dev*' -and $line -notlike '*Driver*' -and $line -notlike '*Runtime*' -and $line -notlike '*Insider*' -and $line -notlike '*VCRedist*' -and $line -notlike '*Edge*' -and $line -notlike '*UI.Xaml*' -and $line -notlike '*Nvidia*')
            {
                $parsedApps += [PSCustomObject]@{
                    Name = $Matches.Trim()
                    Id   = $Matches.Trim()
                    Version = $Matches.Trim()
                    Source = $Matches.Trim()
                }
            }
        }
    }
    remove-item -Path $tempapplist -force
    return $parsedApps
}

# Combine results from both functions
$allSoftware = @()
$allSoftware += Get-installedsoftware -name "*" -exclusions "NVIDIA*,Microsoft*,Intel*,Realtek*"
$allSoftware += Get-LocalApplications

# Display the combined results in a GridView
$allSoftware | Out-GridView -Title "Locally Installed Apps" -PassThru