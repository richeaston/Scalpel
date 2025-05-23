Function Get-WingetVersion {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	
    #check installed version of winget against latest online version
    $localWingetVersion = (winget --version)
	
    $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $LatestVersion = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json | Select-Object -ExpandProperty "tag_name"
	
	
    if ($localWingetVersion -lt $LatestVersion) {
        Write-host " Winget outdated ($localWingetVersion), Installing latest version ($LatestVersion). " -ForegroundColor Yellow -BackgroundColor DarkRed
        try {
            Winget Upgrade Winget
        }
        Catch {
            
        }
        # get latest download url
        $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
        Select-Object -ExpandProperty "assets" |
        Where-Object "browser_download_url" -Match '.msixbundle' |
        Select-Object -ExpandProperty "browser_download_url"
		
        if (!(test-path c:\temp)) { New-Item -Path C:\ -Name Temp -ItemType Directory -Verbose }
        # download
        Invoke-WebRequest -Uri $URL -OutFile "c:\Temp\Setup.msix" -UseBasicParsing
		
        # install
        Add-AppxPackage -Path "c:\Temp\Setup.msix" -ForceApplicationShutdown -InstallAllResources -Register -Verbose
		
        # delete file
        Remove-Item "c:\Temp\Setup.msix" -Force -verbose
		
    }

}

#needs app-installer package and dependencies
Function Install-Winget {
	
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	
    #check installed version of winget against latest online version
    $localWingetVersion = (winget --version)
	
    $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $LatestVersion = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json | Select-Object -ExpandProperty "tag_name"
	
	
    if ($localWingetVersion -lt $LatestVersion) {
        Write-host " Winget outdated ($localWingetVersion), Installing latest version ($LatestVersion). " -ForegroundColor Yellow -BackgroundColor DarkRed
        try {
            Winget Upgrade Winget
        }
        Catch {

        }
        # get latest download url
        $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
        Select-Object -ExpandProperty "assets" |
        Where-Object "browser_download_url" -Match '.msixbundle' |
        Select-Object -ExpandProperty "browser_download_url"
		
        if (!(test-path c:\temp)) { New-Item -Path C:\ -Name Temp -ItemType Directory -Verbose }
        # download
        Invoke-WebRequest -Uri $URL -OutFile "c:\Temp\Setup.msix" -UseBasicParsing
		
        # install
        Add-AppxPackage -Path "c:\Temp\Setup.msix" -ForceApplicationShutdown -InstallAllResources -Register -Verbose
		
        # delete file
        Remove-Item "c:\Temp\Setup.msix" -Force -verbose
		
    }
    else {
        Write-Host ""
        Write-Host " Lasest version of WinGet ($LatestVersion) is installed. " -ForegroundColor Yellow -BackgroundColor DarkGreen
		
    }
	
}

Get-AppxPackage -allusers Microsoft.Store | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppxManifest.xml"}

Write-Host "Checking for Winget" -BackgroundColor Cyan -ForegroundColor Black
if (!(Winget --version)) {
    Write-Warning "Winget not installed, Please Wait."
    Install-Winget
}
else {
    Get-WingetVersion
}

$AppsJson = "c:\temp\winget_apps.json"

if (test-path $AppsJson) {
    Write-host "Apps JSON File Present, ingesting." -BackgroundColor Green -ForegroundColor Blue
    Write-host ""
    try {
        $parsedApps = get-content -path $AppsJson -Raw -Encoding UTF8 | ConvertFrom-Json 
    }
    catch {
        Write-Error "Error processing JSON file: $_"
    }
    #$parsedApps | Sort-Object Name | Format-Table -AutoSize
} else {
    Write-Warning "Apps JSON file not found: $AppsJson"
}


#$parsedApps | Sort-Object Name | Format-Table -AutoSize

Write-host "Installing Software from Manifest, Please Wait..." -BackgroundColor Green -ForegroundColor Yellow
Write-host ""
foreach ($app in ($parsedApps | Sort-Object Name)) {
    if ($null -ne $($app.name) -and $($app.name -ne "")) {
        Write-host "Installing " -NoNewline -ForegroundColor Green
        Write-host $($app.name) -NoNewline -ForegroundColor Yellow
        Write-Host ", Please Wait." -ForegroundColor Green
        Write-host ""
        try {
            # Suppress output by redirecting it to $null
            winget install --id $($app.id) --source $($app.Source) --silent --accept-package-agreements --accept-source-agreements --dependency-Source --ignore-security-hash *> $null 

        }
        Catch {
            # Handle any errors that occur during installation
        }
    }
}
