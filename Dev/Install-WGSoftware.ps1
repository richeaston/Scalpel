Function Get-WingetVersion {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	
    #check installed version of winget against latest online version
    $localWingetVersion = (winget --version)
	
    $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $LatestVersion = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json | Select-Object -ExpandProperty "tag_name"
	
	
    if ($localWingetVersion -lt $LatestVersion) {
        Write-host " Winget outdated ($localWingetVersion), Installing latest version ($LatestVersion). " -ForegroundColor Yellow -BackgroundColor DarkRed
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

Function Install-Winget {
	
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	
    #check installed version of winget against latest online version
    $localWingetVersion = (winget --version)
	
    $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $LatestVersion = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json | Select-Object -ExpandProperty "tag_name"
	
	
    if ($localWingetVersion -lt $LatestVersion) {
        Write-host " Winget outdated ($localWingetVersion), Installing latest version ($LatestVersion). " -ForegroundColor Yellow -BackgroundColor DarkRed
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

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$AppsJson = get-content -path "$dir\winget_apps.json" -Raw

if (test-path $AppsJson) {
    Write-host "Apps JSON File Present, ingesting." -BackgroundColor Green -ForegroundColor Blue
    $parsedApps = ConvertFrom-Json -InputObject $AppsJson
    Write-host ""
    $parsedApps
}

Write-Host "Checking for Winget" -BackgroundColor Cyan -ForegroundColor Black
if (!(Winget --version)) {
    Write-Warning "Winget not installed, Please Wait."
    Install-Winget
}
else {
    Get-WingetVersion
}

$parsedApps | Sort-Object Name | Format-Table -AutoSize

Write-host "Installing Software from Manifest, Please Wait..." -BackgroundColor Green -ForegroundColor Yellow
Write-host ""
foreach ($app in ($parsedApps | Sort-Object Name)) {
    Write-host "Installing " -NoNewline -ForegroundColor Green
    Write-host $($app.name) -NoNewline -ForegroundColor Yellow
    Write-Host ", Please Wait." -ForegroundColor Green
    Write-host ""
    winget install --name $($app.name) --id $($app.id) --silent --accept-package-agreements --accept-source-agreements --dependency-Source --ignore-security-hash
    Write-host ""
}
    
