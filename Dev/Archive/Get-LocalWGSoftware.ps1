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
			if ($line -match '^((?:\S+\s+)+?)(\S+)\s+(\S+)\s+(\S+)$' -and $line -like '*Alpha*' -and $line -like '*Beta*' -and $line -like '*Preview*' -and $line -like '*Canary*' -and $line -like '*Dev*' -and $line -like '*Driver*' -and $line -like '*Runtime*' -and $line -like '*Insider*' -and $line -like '*VCRedist*' -and $line -like '*Edge*' -and $line -like '*UI.Xaml*' -and $line -like '*Nvidia*')
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
	remove-item -Path $tempapplist -force
    return $parsedApps
}

Get-LocalApplications 

# Display or further process the parsed apps
#$parsedApps | Sort-Object Name | Out-GridView -Title "Locally Installed Apps" -PassThru
#$parsedApps | Export-Csv c:\Temp\applist.csv -Encoding UTF8 -NoClobber -Force