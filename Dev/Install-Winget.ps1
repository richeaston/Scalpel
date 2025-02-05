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

Install-Winget
