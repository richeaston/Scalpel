<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.197
	 Created on:   	23/01/2025 10:14
	 Created by:   	Rich Easton
	 Organization: 	PoSH Codex
	 Filename:     	Get-software
	===========================================================================
	.DESCRIPTION
		Get-software installed on current system.

#>

Function Get-installedsoftware 
{
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
	
	foreach ($p in $paths)
	{
		if ($name)
		{
			
			$installed = Get-ItemProperty "$p\*" | Where-Object { $_.DisplayName -like $name } | Select-Object DisplayName, DisplayVersion, UninstallString, SystemComponent | sort-object DisplayName
		}
		foreach ($exclusion in ($exclusions.split(',')))
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
		$sassets | Sort-Object Name | Format-Table -AutoSize -Wrap
	}
}

#search for the software (including wildcard * pre and post), example "Epic*" and add exclusions as required (including wildcard * pre and post), seperating by a "," exmaple "NVIDIA*,Microsoft*,Intel*,Realtek*"
Get-installedsoftware -name "*" -exclusions "NVIDIA*,Microsoft*,Intel*"
