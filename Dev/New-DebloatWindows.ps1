#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Debloat Script
.DESCRIPTION
    Removes bloatware, disables Copilot/Recall, uninstalls Microsoft Edge and OneDrive.
    Must be run as Administrator.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ─────────────────────────────────────────────
# Helper: Winget uninstall with consistent args
# ─────────────────────────────────────────────
function Invoke-WingetUninstall {
    param([string]$App)
    Write-Host "  [winget] Uninstalling: $App" -ForegroundColor Yellow
    winget uninstall $App --silent --force --purge --accept-source-agreements --ignore-warnings 2>&1 | Out-Null
}

# ─────────────────────────────────────────────
# Helper: Remove AppX package (current + provisioned)
# ─────────────────────────────────────────────
function Remove-AppXSafely {
    param([string]$PackageName)
    Write-Host "  [appx] Removing: $PackageName" -ForegroundColor Cyan

    Get-AppxPackage -Name $PackageName -AllUsers |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -like "*$PackageName*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# ─────────────────────────────────────────────
# 1. Kill running processes that block uninstall
# ─────────────────────────────────────────────
Write-Host "`n[1/5] Stopping blocking processes..." -ForegroundColor Magenta
'teams', 'msedge', 'OneDrive', 'OneDriveSetup' | ForEach-Object {
    Stop-Process -Name "*$_*" -Force -ErrorAction SilentlyContinue
}

# ─────────────────────────────────────────────
# 2. Winget uninstalls
# ─────────────────────────────────────────────
Write-Host "`n[2/5] Uninstalling via Winget..." -ForegroundColor Magenta

$wingetApps = @(
    'Copilot'
    'Dev Home'
    'Feedback Hub'
    'Game Bar'
    'Game Speech Window'
    'LinkedIn'
    'LinkedInforWindows'
    'Microsoft 365 (Office)'
    'Microsoft 365 Copilot'
    'Microsoft Clipchamp'
    'Microsoft News'
    'Microsoft To Do'
    'MSN Weather'
    'Media Player'
    'Outlook'
    'Power Automate'
    'Quick Assist'
    'Solitaire & Casual Games'
    'Sound Recorder'
    # 'Sticky Notes'   # uncomment to remove
    'Teams'
    'Windows Clock'
    'Xbox TCUI'
    'Xbox Identity Provider'
    'xbox'
)

$wingetApps | Sort-Object | ForEach-Object { Invoke-WingetUninstall $_ }

# ─────────────────────────────────────────────
# 3. Uninstall Microsoft Edge
#    Edge's own uninstaller must be called directly;
#    winget alone is often insufficient.
# ─────────────────────────────────────────────
Write-Host "`n[3/5] Uninstalling Microsoft Edge..." -ForegroundColor Magenta

# Try winget first
Invoke-WingetUninstall 'Microsoft Edge'

# Fall back to Edge's own uninstaller if still present
$edgeSetups = @(
    "$env:ProgramFiles(x86)\Microsoft\Edge\Application",
    "$env:ProgramFiles\Microsoft\Edge\Application"
) | ForEach-Object {
    if (Test-Path $_) {
        Get-ChildItem $_ -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue
    }
}

foreach ($setup in $edgeSetups) {
    if ($setup) {
        Write-Host "  Running Edge uninstaller: $($setup.FullName)" -ForegroundColor Yellow
        & $setup.FullName --uninstall --system-level --verbose-logging --force-uninstall 2>&1 | Out-Null
    }
}

# Remove Edge AppX packages
Remove-AppXSafely 'Microsoft.MicrosoftEdge'
Remove-AppXSafely 'Microsoft.MicrosoftEdge.Stable'

# Block Edge from being reinstalled via Windows Update
$edgePolicies = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
if (-not (Test-Path $edgePolicies)) { New-Item -Path $edgePolicies -Force | Out-Null }
Set-ItemProperty -Path $edgePolicies -Name 'InstallDefault' -Value 0 -Type DWord -Force

# ─────────────────────────────────────────────
# 4. Uninstall OneDrive
# ─────────────────────────────────────────────
Write-Host "`n[4/5] Uninstalling OneDrive..." -ForegroundColor Magenta

Invoke-WingetUninstall 'Microsoft OneDrive'

# Run built-in uninstaller
$oneDriveSetups = @(
    "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe",
    "$env:SYSTEMROOT\System32\OneDriveSetup.exe",
    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
)

foreach ($setup in $oneDriveSetups) {
    if (Test-Path $setup) {
        Write-Host "  Running OneDrive uninstaller: $setup" -ForegroundColor Yellow
        & $setup /uninstall 2>&1 | Out-Null
        break
    }
}

# Remove AppX packages
Remove-AppXSafely 'Microsoft.OneDrive'
Remove-AppXSafely 'Microsoft.OneDriveSync'

# Clean up OneDrive leftovers
$oneDrivePaths = @(
    "$env:USERPROFILE\OneDrive",
    "$env:LOCALAPPDATA\Microsoft\OneDrive",
    "$env:PROGRAMDATA\Microsoft OneDrive",
    "$env:SYSTEMDRIVE\OneDriveTemp"
)
$oneDrivePaths | Where-Object { Test-Path $_ } | ForEach-Object {
    Write-Host "  Removing: $_" -ForegroundColor DarkYellow
    Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
}

# Remove OneDrive from Explorer sidebar
$clsidPath = 'HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
if (Test-Path $clsidPath) {
    Set-ItemProperty -Path $clsidPath -Name 'System.IsPinnedToNameSpaceTree' -Value 0 -Force
}

# Block OneDrive from auto-running at startup
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
Remove-ItemProperty -Path $runKey -Name 'OneDrive' -ErrorAction SilentlyContinue

# ─────────────────────────────────────────────
# 5. Remove AppX packages
# ─────────────────────────────────────────────
Write-Host "`n[5/6] Removing AppX packages..." -ForegroundColor Magenta

$appxPackages = @(
    'Microsoft.BingSearch'
    'Microsoft.BingWeather'
    'Microsoft.Copilot'
    'Microsoft.GamingApp'                  # Xbox Game Bar
    'Microsoft.GetHelp'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.WebExperience'              # Widgets
    'Microsoft.Windows.DevHome'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.YourPhone'
    'Microsoft.ZuneMusic'                  # Media Player
    'MicrosoftWindows.CrossDevice'
    'LinkedIn'
    'LinkedInforWindows'
)

$appxPackages | Sort-Object | ForEach-Object { Remove-AppXSafely $_ }

# ─────────────────────────────────────────────
# 6. Disable Copilot and Recall features
# ─────────────────────────────────────────────
Write-Host "`n[6/6] Disabling Copilot and Recall features..." -ForegroundColor Magenta

$optionalFeatures = @('Microsoft.Windows.Copilot', 'Recall')

foreach ($feature in $optionalFeatures) {
    Write-Host "  Checking: $feature" -ForegroundColor Cyan

    $dismOutput = DISM /Online /Get-FeatureInfo /FeatureName:$feature 2>&1
    $stateMatch = $dismOutput | Select-String -Pattern '^State\s*:\s*(.+)$'

    if ($stateMatch) {
        $state = $stateMatch.Matches[0].Groups[1].Value.Trim()
        Write-Host "    State: $state"

        if ($state -eq 'Enabled') {
            Write-Host "    Disabling $feature..." -ForegroundColor Yellow
            DISM /Online /Disable-Feature /FeatureName:$feature /NoRestart 2>&1 | Out-Null
        }
    }
    else {
        Write-Host "    Feature not found or state unavailable." -ForegroundColor DarkGray
    }
}

# Also disable Copilot via Group Policy registry key
$copilotPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
if (-not (Test-Path $copilotPolicyPath)) { New-Item -Path $copilotPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $copilotPolicyPath -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord -Force

Write-Host "`n✔ Debloat complete. A restart is recommended." -ForegroundColor Green
