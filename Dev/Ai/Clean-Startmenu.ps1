<#
.SYNOPSIS
    Configures Windows Start Menu: Hides "Recommended" content and restarts Explorer.
    
.NOTES
    - Removes "Recently Added" apps.
    - Removes "Recent Items/Files" (The "Recommended" section).
    - Safely restarts Windows Explorer.
    - DOES NOT delete shortcuts (Safety Fix).
#>

Write-Host "Starting Start Menu Configuration..." -ForegroundColor Cyan

# --- SECTION 1: Hide "Recommended" & Recent Items ---
# This handles the "Recommended" section in Windows 11 and "Recent" in Windows 10
try {
    $advRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    # 1. Hide "Recommended" (Tips, Shortcuts, Promotions - Windows 11 specific)
    # Note: Requires valid Windows License for full effect
    Set-ItemProperty -Path $advRegPath -Name "Start_IrisRecommendations" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    
    # 2. Hide "Recently Opened Items" (Files in Recommended)
    Set-ItemProperty -Path $advRegPath -Name "Start_TrackDocs" -Value 0 -Type DWord -Force
    
    # 3. Hide "Recently Added Apps"
    Set-ItemProperty -Path $advRegPath -Name "Start_TrackProgs" -Value 0 -Type DWord -Force

    Write-Host "[OK] 'Recommended' and 'Recent' sections hidden." -ForegroundColor Green
} catch {
    Write-Error "Error configuring Registry: $_"
}

# --- SECTION 2: Unpinning Apps (Explanation) ---
# Note: Windows 10/11 does not allow a simple PowerShell loop to "Unpin" items programmatically
# without using Enterprise MDM policies or complex LayoutModification.json files.
# The previous logic was removed because it deletes the actual App Shortcuts, not the Pins.

Write-Host "Note: Pinned items were not removed to prevent deletion of installed shortcuts." -ForegroundColor Yellow
Write-Host "To clear pins completely, right-click the Start Menu > Start Settings > Layout." -ForegroundColor Gray


# --- SECTION 3: Restart Explorer to Apply Changes ---
Write-Host "Restarting Windows Explorer..." -ForegroundColor Cyan

try {
    # Cleanly stop the explorer process
    Stop-Process -Name "explorer" -Force -ErrorAction Stop
    
    # Wait a moment for the system to auto-restart it, or force start if it hangs
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
    
    Write-Host "[OK] Explorer restarted. Start Menu updated." -ForegroundColor Green
} catch {
    Write-Error "Failed to restart Explorer. You may need to restart it manually via Task Manager."
}

Write-Host "Script Finished." -ForegroundColor Cyan
