<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.197
	 Created on:   	23/01/2025 10:54
	 Created by:   	Rich Easton
	 Organization: 	PoSH Codex
	 Filename:    	Get-Services 	
	===========================================================================
	.DESCRIPTION
		Gets all services that are running with automatic or manual starttype.
#>

#get-service | where { $_.Status -ne "Stopped" -and $_.Starttype -ne "Disabled" } | Select-Object Name, ServiceName, CanShutdown, CanStop, Status, Starttype | Group-Object Starttype | ft -a
get-service | where { $_.Status -ne "Stopped" -and $_.Starttype -ne "Disabled" } | Select-Object Name, ServiceName, CanShutdown, CanStop, Status, Starttype | ft -a
