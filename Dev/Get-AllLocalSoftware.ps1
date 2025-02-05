<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.197
	 Created on:   	23/01/2025 10:14
	 Created by:   	Rich Easton
	 Organization: 	PoSH Codex
	 Filename:     	Get-software including WInget check for installed software
	===========================================================================
	.DESCRIPTION
		Get-software installed on current system.

#>

Function Get-installedsoftware {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$name,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]$exclusions
	)
	$paths = @("HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
	$sassets = @()
		
	foreach ($p in $paths) {
		if ($name) {
			$installed = Get-ItemProperty "$p\*" | Where-Object { $_.DisplayName -like $name } | Select-Object * | sort-object DisplayName
			#	$installed = Get-ItemProperty "$p\*" | Where-Object { $_.DisplayName -like $name } | Select-Object DisplayName, DisplayVersion, UninstallString, SystemComponent | sort-object DisplayName
		}
		foreach ($exclusion in ($exclusions.split(','))) {
			$installed = $installed | Where-Object { $_.DisplayName -notlike $exclusion }
		}
		
		foreach ($i in $installed) {
			$item = [pscustomobject]@{
				Name      = $i.Displayname
				Version   = $i.DisplayVersion
				Id        = $i.Publisher
				Uninstall = $i.UninstallString
				#Hive            = $p
				#SystemComponent = $i.SystemComponent
				Source    = "Local"
			}
			if ($null -ne $item.name) {
				$sassets += $item
			}
		}
		#detect software installs
	}
	Return $sassets

}

Function Find-WGSoftware {
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$name,

		[Parameter()]
		[string]$version # Optional version parameter
	)

	$appsearch = winget find $Name

	# Skip header lines and empty lines
	$validLines = $appsearch | Where-Object {
		$_ -notmatch "^Name\s*Id\s*Version\s*Source" -and
		$_ -notmatch "^-+$" -and
		$_.Trim() -ne ""
	}

	$parsedApps = @() # Initialize an empty array

	foreach ($line in $validLines) {
		# Regex to capture the entire name, even with multiple words
		if ($line -match '^((?:\S+\s+)+?)(\S+)\s+(\S+)\s+(\S+)$') {
			$appName = $Matches[1].Trim()
			$appVersion = $Matches[3].Trim()
            
			# Check for exclusion keywords before creating the object
			if ($appName -notlike '*Alpha*' -and $appName -notlike '*Beta*' -and $appName -notlike '*Preview*' -and $appName -notlike '*Canary*' -and $appName -notlike '*Dev*' -and $appName -notlike '*Driver*' -and $appName -notlike '*Runtime*' -and $appName -notlike '*Insider*') {

				$app = [PSCustomObject]@{
					Name    = $appName
					Id      = $Matches[2].Trim()
					Version = $appVersion
					Source  = $Matches[4].Trim()
				}

				if ($version) {
					# If version is specified
					if ($appVersion -eq $version) {
						# Match the version
						$parsedApps += $app # Add only if version matches
						break # Exit loop after finding the first match
					}
				}
				else {
					# If no version is specified
					$parsedApps += $app # Add all matching apps
				}
			}
		}
	}

	return $parsedApps # Return the array of PSCustomObjects
}

function Get-WGApplications {
	
	$tempapplist = "c:\temp\appslist.json"
	$wingetPackages = winget export -o $tempapplist --include-versions --accept-source-agreements
	$appsData = Get-Content -Path $tempapplist | ConvertFrom-Json
	$apparray = @()
	
	# Iterate through each source in the JSON
	foreach ($source in $appsData.Sources) {
		foreach ($package in $source.Packages) {
			$apparray += $package
		}
	}
	
	$parsedApps = @()
	foreach ($app in $apparray) {
		$appsearch = winget search $app.PackageIdentifier
		
		# Skip header lines and empty lines
		$validLines = $appsearch | Where-Object {
			$_ -notmatch "^Name\s*Id\s*Version\s*Source" -and
			$_ -notmatch "^-+$" -and
			$_.Trim() -ne ""
		}
		
		foreach ($line in $validLines) {
			# Regex to capture the entire name, even with multiple words
			if ($line -match '^((?:\S+\s+)+?)(\S+)\s+(\S+)\s+(\S+)$' -and $line -notlike '*Alpha*' -and $line -notlike '*Beta*' -and $line -notlike '*Preview*' -and $line -notlike '*Canary*' -and $line -notlike '*Dev*' -and $line -notlike '*Driver*' -and $line -notlike '*Runtime*' -and $line -notlike '*Insider*' -and $line -notlike '*VCRedist*' -and $line -notlike '*Edge*' -and $line -notlike '*UI.Xaml*' -and $line -notlike '*Nvidia*') {
				$parsedApps += [PSCustomObject]@{
					Name    = $Matches[1].Trim()
					Id      = $Matches[2].Trim()
					Version = $Matches[3].Trim()
					Source  = $Matches[4].Trim()
				}
			}
		}
	}
	remove-item -Path $tempapplist -force
	return $parsedApps
}

$WGLocalApps = Get-WgApplications | Sort-Object Name
$WGLocalApps

$applist = Get-installedsoftware -name "*" -exclusions "NVIDIA*,Microsoft*,Intel*,Realtek*,NvCPL*"


# Filter the applist based on keyword matching
$filteredApplist = $applist | Where-Object {
	$app = $_
	$matchFound = $false
	if (!($app.Uninstall -like '*steam://uninstall*')) {
		foreach ($wgApp in $WGLocalApps) {
			
			
			
			
			$appKeywords = $app.Name -split '\s+'
			$wgAppKeywords = $wgApp.Name -split '\s+'

			foreach ($keyword in $appKeywords) {
				
				if ($wgAppKeywords -contains $keyword) {
					write-host $wgAppKeywords
					write-host $keyword
					$matchFound = $true
					break
				}
			}
			if ($matchFound) { break }
		}
		!$matchFound
	}
}

$filteredApplist

foreach ($app in $filteredApplist) {
	Write-Host "`nSearching for: '$($app.name)' in Winget."

	$software = Find-WGSoftware -name "$($app.Name)" -version "$($app.version)"

	if ($software) {
		# Check if $software is an array (multiple results) or a single object
		if ($software -is [array]) {
			$found = $false  # Flag to track if a suitable match is found

			foreach ($item in $software) {
				# Iterate through results if it's an array
				if (!($item.Name -like '*No package found*')) {
					Write-Host "`tFound " -NoNewline
					Write-host "'$($item.name)' " -ForegroundColor Cyan -NoNewline
					Write-host ",Version: " -NoNewline
					Write-host "'$($item.Version)' " -ForegroundColor Cyan -NoNewline
					Write-host ",Package ID: " -NoNewline
					Write-host "'$($item.Id)' " -ForegroundColor Cyan
					$found = $true  # Set flag to true as we found a match
					break # Exit the inner loop after finding the first match
				}
			}

			if (!$found) {
				# If no suitable package was found in the array
				Write-Host "`t'$($app.Name)' version '$($app.version)' not found! (No suitable package)" -ForegroundColor Magenta
			}

		}
		else {
			# if it's a single object
			if (!($software.Name -like '*No package found*')) {
				Write-Host "`tFound " -NoNewline
				Write-host "'$($software.name)' " -ForegroundColor Cyan -NoNewline
				Write-host ",Version: " -NoNewline
				Write-host "'$($software.Version)' " -ForegroundColor Cyan -NoNewline
				Write-host ",Package ID: " -NoNewline
				Write-host "'$($software.Id)' " -ForegroundColor Cyan
			}
			else {
				$software = Find-WGSoftware -name "$($app.Name)"
				if ($software) {
					if ($software -is [array]) {
						$found = $false
						foreach ($item in $software) {
							if (!($item.Name -like '*No package found*')) {
								Write-Host "`tFound " -NoNewline
								Write-host "'$($item.name)' " -ForegroundColor Cyan -NoNewline
								Write-host ",Version: " -NoNewline
								Write-host "'$($item.Version)' " -ForegroundColor Cyan -NoNewline
								Write-host ",Package ID: " -NoNewline
								Write-host "'$($item.Id)' " -ForegroundColor Cyan
								$found = $true
								break
							}
						}
						if (!$found) {
							Write-Host "`t'$($app.Name)' not found! (No suitable package)" -ForegroundColor Magenta
						}

					}
					else {
						if (!($software.Name -like '*No package found*')) {
							Write-Host "`tFound " -NoNewline
							Write-host "'$($software.name)' " -ForegroundColor Cyan -NoNewline
							Write-host ",Version. " -NoNewline
							Write-host "'$($software.Version)' " -ForegroundColor Cyan -NoNewline
							Write-host ",Package ID: " -NoNewline
							Write-host "'$($software.Id)' " -ForegroundColor Cyan
						}
						else {
							Write-Host "`t'$($app.Name)' not found! (No suitable package)" -ForegroundColor Magenta
						}
					}
				}
				else {
					Write-Host "`t'$($app.Name)' not found!" -ForegroundColor Magenta
				}
			}
		}
	}
 else {
		Write-Host "`t'$($app.Name)' version '$($app.version)' not found!" -ForegroundColor Magenta
	}
}