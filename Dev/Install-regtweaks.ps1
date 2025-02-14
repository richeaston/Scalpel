# -------------------------------------------------------------------
# Registry Tweaks
# -------------------------------------------------------------------
Write-host "Applying Registry Tweaks" -ForegroundColor Yellow -BackgroundColor Cyan
write-host ""
$regtweaks = @(
    'Remove Recent Applications,HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,Start_TrackProgs,0',
    'Remove Recommended Applications,HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,ShowAppsList,0',
    'Use More Pins Configuration,HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,Start_Layout,2',
    '--- Dark Mode Tweak ---,HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,AppsUseLightTheme,0',
    '--- Dark Mode Tweak ---,HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,SystemUsesLightTheme,0',
    'Disable Telemetry Data Collection,HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection,AllowTelemetry,0',
    'Disable Telemetry Data Collection,HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection,AllowTelemetry,0',
    'Disable Location Tracking,HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration,Status,0',
    'Disable Advertising ID,HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo,Enabled,0',
    'Disable Diagnostics Tracking,HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack,DiagTrackEnabled,0'
)

foreach ($regitem in $regtweaks) {
    $regtweak = $regitem.split(",")
    $description = $regtweak[0]
    $path = $regtweak[1]
    $name = $regtweak[2]
    $value = $regtweak[3]

    Write-host "`t$description" -ForegroundColor Yellow

    try {
        Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord -Force 
    }
    Catch {
        # Create *all* missing parent paths
        $currentPath = $path
        while (!(Test-Path -Path (Split-Path $currentPath) -PathType Container)) {
            $currentPath = Split-Path $currentPath
            Write-Verbose "Creating parent path: $currentPath"
            New-Item -Path $currentPath -ItemType Directory -Force  
        }

        # Now try setting the property again. This time it should succeed.
        Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

Write-host "`nApplied Registry Tweaks" -BackgroundColor Green -ForegroundColor Yellow

# Disable IPV6 
# Get all network interfaces
$netInterfaces = Get-NetAdapter

# Loop through each network interface
foreach ($interface in $netInterfaces) {
  try {
    # Disable IPv6 for the current interface
    Disable-NetAdapterBinding -Name $interface.Name -ComponentID "ms_tcpip6" -PassThru | Out-Null
    Write-Host "Disabled IPv6 for interface: $($interface.Name)"
  } catch {
    Write-Error "Error disabling IPv6 for interface $($interface.Name): $_"
  }
}

Set-ItemProperty -Path  "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters" -Name "DisabledComponents" -Value "32" -Force 
Set-ItemProperty -Path  "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters" -Name "DisabledComponents" -Value "1" -Force

Write-Host "Finished disabling IPv6."
write-host ""
