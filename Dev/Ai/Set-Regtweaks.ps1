# -------------------------------------------------------------------
# Registry Tweaks & Optimization Script
# -------------------------------------------------------------------

# 1. Check for Administrator Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Administrator."
    Break
}

Write-Host "Applying Registry Tweaks..." -ForegroundColor Yellow -BackgroundColor Cyan
Write-Host ""

# 2. Configuration: Using Objects instead of CSV strings for safety and readability
$regTweaks = @(
    [PSCustomObject]@{ Description = "Remove Recent Applications";      Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Remove Recommended Applications"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowAppsList";     Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Use More Pins Configuration";     Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_Layout";     Value = 2; Type = "DWord" }
    [PSCustomObject]@{ Description = "Dark Mode (Apps)";                Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme";   Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Dark Mode (System)";              Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Disable Telemetry (Policies)";    Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection";          Name = "AllowTelemetry";       Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Disable Telemetry (Current)";     Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Disable Location Tracking svc";   Path = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"; Name = "Status";             Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Disable Advertising ID";          Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo";   Name = "Enabled";              Value = 0; Type = "DWord" }
    [PSCustomObject]@{ Description = "Disable Diagnostics Tracking";    Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack"; Name = "DiagTrackEnabled"; Value = 0; Type = "DWord" }
)

# 3. Main Loop
foreach ($tweak in $regTweaks) {
    Write-Host "`t$($tweak.Description)" -ForegroundColor Yellow
    
    try {
        # Check if the registry path exists; if not, create it recursively
        if (!(Test-Path -Path $tweak.Path)) {
            Write-Verbose "Path not found. Creating: $($tweak.Path)"
            New-Item -Path $tweak.Path -ItemType Directory -Force | Out-Null
        }

        # Apply the property
        Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -Type $tweak.Type -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to apply tweak: $($tweak.Description). Error: $_"
    }
}

Write-Host "`nRegistry Tweaks Applied." -BackgroundColor Green -ForegroundColor Black
Write-Host ""

# -------------------------------------------------------------------
# Disable IPv6 
# -------------------------------------------------------------------
Write-Host "Disabling IPv6..." -ForegroundColor Yellow

# Disable on Network Adapters
$netInterfaces = Get-NetAdapter -ErrorAction SilentlyContinue
if ($netInterfaces) {
    foreach ($interface in $netInterfaces) {
        try {
            Disable-NetAdapterBinding -Name $interface.Name -ComponentID "ms_tcpip6" -PassThru | Out-Null
            Write-Host "`tDisabled IPv6 for interface: $($interface.Name)" -ForegroundColor Gray
        } catch {
            Write-Warning "Could not disable IPv6 for interface $($interface.Name)"
        }
    }
}

# Disable via Registry (System Wide)
# Note: 0xff (255) disables IPv6 completely. 
#       0x20 (32) prefers IPv4 over IPv6.
$ipv6Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
try {
    if (!(Test-Path $ipv6Path)) { New-Item -Path $ipv6Path -Force | Out-Null }
    
    # Using 0xFF (255) ensures it is fully disabled as requested. 
    # Your original script set it to 32 then 1. 1 is acceptable, but 0xFF is the standard "Disable" hex value.
    Set-ItemProperty -Path $ipv6Path -Name "DisabledComponents" -Value 0xFF -Type DWord -Force
    Write-Host "`tSystem-wide IPv6 Registry Key set to Disabled (0xFF)." -ForegroundColor Gray
}
catch {
    Write-Error "Failed to set DisabledComponents registry key."
}

Write-Host "`nFinished." -BackgroundColor Green -ForegroundColor Black
Write-Host ""
