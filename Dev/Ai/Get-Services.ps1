<#	
	.NOTES
	===========================================================================
	 Created by: 	Rich Easton (PoSH Codex)
	 Refined by:    Gemini AI
	 Filename:    	Get-Services.ps1
	===========================================================================
	.DESCRIPTION
		Gets all services that are not stopped and not disabled, then exports
        them to a JSON file in the script's directory.
#>

# 1. Determine the output path safely
# $PSScriptRoot is the standard variable for the script's directory.
# We add a fallback to $PWD in case you copy-paste this into the console directly.
$scriptDir  = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }
$outputFile = Join-Path -Path $scriptDir -ChildPath "Services.json"

Write-Host "Scanning local services..." -ForegroundColor Cyan

try {
    # 2. Get and Filter Services
    # We select DisplayName as well, as "Name" is often obscure (e.g. wuauserv vs Windows Update)
    $serviceList = Get-Service | Where-Object { 
        $_.Status -ne "Stopped" -and $_.StartType -ne "Disabled" 
    } | Select-Object Name, DisplayName, StartType, Status, CanStop, CanShutdown

    # 3. Export to JSON
    # We sort by Name for readability in the JSON file
    $serviceList | Sort-Object Name | ConvertTo-Json -Depth 2 | Out-File -FilePath $outputFile -Encoding UTF8 -Force

    # 4. Success Output
    Write-Host "Successfully exported $($serviceList.Count) services." -ForegroundColor Green
    Write-Host "File saved to: $outputFile" -BackgroundColor Blue -ForegroundColor White
}
catch {
    Write-Error "Failed to export services: $($_.Exception.Message)"
}
