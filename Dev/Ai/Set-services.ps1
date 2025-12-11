<#
.SYNOPSIS
    Configures Windows Services based on a JSON configuration file.
    
.NOTES
    - Requires Administrator privileges.
    - JSON format expected: [{"ServiceName": "Name", "StartType": 2}, ...]
    - StartTypes: 0=Boot, 1=System, 2=Automatic, 3=Manual, 4=Disabled
#>

# 1. Check for Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    break
}

# 2. Setup Paths and Load Data
$scriptDir = $PSScriptRoot  # Cleaner way to get script directory in modern PowerShell
$jsonPath  = "$scriptDir\Services.json"

if (-not (Test-Path -Path $jsonPath)) {
    Write-Error "Configuration file not found: $jsonPath"
    break
}

try {
    $services = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to read or parse JSON file. Please check the format."
    break
}

Write-Host "Processing $($services.Count) services..." -ForegroundColor Cyan

# 3. Process Services
foreach ($item in $services) {
    $svcName = $item.ServiceName
    
    try {
        # Attempt to get the service object once
        $serviceObj = Get-Service -Name $svcName -ErrorAction Stop
        
        # --- STOP SERVICE LOGIC ---
        if ($serviceObj.Status -eq "Running") {
            Write-Host "[$svcName] Stopping..." -NoNewline
            Stop-Service -InputObject $serviceObj -Force -ErrorAction Stop
            Write-Host " Done." -ForegroundColor Green
        }

        # --- CONFIGURE STARTUP TYPE LOGIC ---
        # Map numeric JSON values to PowerShell StartType enums
        switch ($item.StartType) {
            2 { $startMode = "Automatic" }
            3 { $startMode = "Manual" }
            4 { $startMode = "Disabled" }
            # 0 (Boot) and 1 (System) are kernel-level and rarely set via script for standard services.
            # We treat them as valid strings, but Set-Service may reject them for non-drivers.
            0 { $startMode = "Boot" }
            1 { $startMode = "System" }
            default { 
                Write-Warning "[$svcName] Unknown StartType value: $($item.StartType). Skipping."
                continue 
            }
        }

        # Only update if the config is different to save time/logs
        if ($serviceObj.StartType -ne $startMode) {
            Set-Service -InputObject $serviceObj -StartupType $startMode -ErrorAction Stop
            Write-Host "[$svcName] Startup set to '$startMode'." -ForegroundColor Green
        } else {
            Write-Host "[$svcName] Already set to '$startMode'." -ForegroundColor Gray
        }

    } catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
        # Specific catch for "Service not found"
        Write-Host "[$svcName] Service does not exist." -ForegroundColor Yellow
    } catch {
        # Catch generic errors (permissions, locks, etc.)
        Write-Error "[$svcName] Failed: $($_.Exception.Message)"
    }
}

Write-Host "Configuration Complete." -ForegroundColor Cyan
