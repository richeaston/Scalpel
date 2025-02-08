function Clear-StartMenuPinnedApps {
    # Get the path to the current user's Start Menu layout file
    $layoutFile = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin"
  
    # Check if the layout file exists
    if (Test-Path $layoutFile) {
      # Clear the contents of the layout file
      Clear-Content $layoutFile -Force
  
      # Restart the Start Menu process to apply the changes
      get-process -name StartMenuExperienceHost | stop-process -Force | start-process -FilePath "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe"
    } else {
      Write-Warning "Start Menu layout file not found: $layoutFile"
    }
  }

$bloatpackages = @('Copilot','Dev Home','Game Bar','Game Speech Window','Feedback hub','Microsoft Bing Search','LinkedIn','LinkedInforWindows','Microsoft Clipchamp','Microsoft News','Microsoft OneDrive','Microsoft To Do','MSN Weather','Media Player','Outlook','OneDrive','Power Automate','Quick Assist','Solitaire & Casual Games','Sound Recorder','Sticky Notes','Teams','Windows Clock','Xbox TCUI', 'Xbox Identity Provider','xbox','Microsoft 365 Copilot','Microsoft 365 (Office)')
Stop-Process -Name "*teams*" -Force -ErrorAction SilentlyContinue

# Configure Winget to accept source agreements
#Winget source update --name msstore --accept-source-agreements --ignore-warnings

#uninstall via winget
foreach ($app in ($bloatpackages | sort-object)) {
    try {
        Write-Host "Trying to Uninstall $app, Please Wait." -ForegroundColor Yellow
        Winget uninstall $app --silent --force --purge --verbose --accept-source-agreements --ignore-warnings
    }
    catch {
        "No installed package found matching input criteria."
    }
}
Write-host ""
#Uninstall Appx Packages
$appxpackages = @('MicrosoftWindows.CrossDevice', 'Microsoft.MicrosoftEdge.Stable', 'Microsoft.ZuneMusic', 'Microsoft.YourPhone', 'Microsoft.XboxGamingOverlay', 'LinkedIn','LinkedInforWindows', 'Microsoft.GetHelp', 'Microsoft.Windows.DevHome', "Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe!Microsoft.MicrosoftOfficeHub", "Microsoft.Copilot_8wekyb3d8bbwe!App", "Microsoft.GetHelp_8wekyb3d8bbwe!App", "Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe!PAD.Console","Microsoft.BingWeather_8wekyb3d8bbwe!App" )
foreach ($appx in ($appxpackages | Sort-object)) {
    Write-host "Trying to uninstalling $appx, Please Wait."
    Get-AppxPackage $appx -AllUsers -Verbose | Remove-AppxPackage -AllUsers -Verbose -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$appx*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-host ""
Write-host "Disabling Copilot and recall" -ForegroundColor Yellow
dism /online /remove-package /package-name:Microsoft.Windows.Copilot
DISM /Online /Disable-Feature /FeatureName:Recall

write-host ""
Write-host "Other Registry Tweaks" -ForegroundColor Yellow
# -------------------------------------------------------------------
# Registry Tweaks
# -------------------------------------------------------------------
Write-host "Applying Registry Tweaks" -ForegroundColor Yellow

# --- Start Menu Tweaks ---
# Remove Recent Applications
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type DWord -Force

# Remove Recommended Applications
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowAppsList" -Value 0 -Type DWord -Force

# Use "More Pins" Configuration
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value 2 -Type DWord -Force

# --- Dark Mode Tweak ---
# Set Windows Theme to Dark Mode
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

# --- Privacy Tweaks ---
# Disable Telemetry Data Collection
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force

# Disable Location Tracking
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0 -Type DWord -Force

# Disable Advertising ID
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force

# Disable Handwriting Data Sharing
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# Disable Diagnostics Tracking
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" -Name "DiagTrackEnabled" -Value 0 -Type DWord -Force

Clear-StartMenuPinnedApps

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
Write-Host "Finished processing Bloatware and Tweaks." -ForegroundColor Green