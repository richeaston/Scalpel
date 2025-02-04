<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.197
	 Created on:   	24/01/2025 14:41
	 Created by:   	Rich Easton
	 Organization: 	PoSH Codex
	 Filename:     	Scapel.psm1
	-------------------------------------------------------------------------
	 Module Name: Scapel
	===========================================================================
#>

<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.197
	 Created on:   	23/01/2025 11:08
	 Created by:   	Rich Easton
	 Organization: 	PoSH Codex
	 Filename:     	Install-Winget	
	===========================================================================
	.DESCRIPTION
		Installs latest version of Winget.
#>

Function Install-Winget
{
	
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	
	#check installed version of winget against latest online version
	$localWingetVersion = (winget --version)
	
	$URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	$LatestVersion = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json | Select-Object -ExpandProperty "tag_name"
	
	
	if ($localWingetVersion -lt $LatestVersion)
	{
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
	else
	{
		Write-Host ""
		Write-Host " Lasest version of WinGet ($LatestVersion) is installed. " -ForegroundColor Yellow -BackgroundColor DarkGreen
		
	}
	
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
					Name = $Matches[1].Trim()
					Id   = $Matches[2].Trim()
					Version = $Matches[3].Trim()
					Source = $Matches[4].Trim()
				}
			}
		}
	}
	
}

function Get-LocalServices
{
	get-service | where { $_.Status -ne "Stopped" -and $_.Starttype -ne "Disabled" } | Select-Object Name, ServiceName, CanShutdown, CanStop, Status, Starttype
}



