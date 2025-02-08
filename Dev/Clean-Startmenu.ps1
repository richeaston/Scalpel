# Unpin all apps (same as before)
$startMenuPinsPath = [Environment]::GetFolderPath("StartMenu") + "\Programs"
$pinnedItems = Get-ChildItem -Path $startMenuPinsPath

foreach ($item in $pinnedItems) {
  try {
    if ($item.Extension -eq ".lnk") {
      Remove-Item -Path $item.FullName -Force -ErrorAction Stop
      Write-Host "Unpinned shortcut: $($item.Name)"
    } elseif ($item.Attributes -eq "Directory") {
      Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
      Write-Host "Unpinned folder: $($item.Name)"
    }
    else{
        Write-Host "Skipping item (not a shortcut or folder): $($item.Name)"
    }
  } catch {
    Write-Error "Error unpinning $($item.Name): $_"
  }
}

Write-Host "Finished clearing pinned apps from Start Menu."

# Hide the "Recommended" section (new part)
try {
  $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage"
  Set-ItemProperty -Path $regPath -Name "ShowRecent" -Value 0 -Force
  Write-Host "Hidden the 'Recommended' section."
} catch {
  Write-Error "Error hiding 'Recommended' section: $_"
}

Write-Host "Finished configuring Start Menu."

    # Restart the Windows Explorer
    taskkill.exe /F /IM "explorer.exe"
    Start-Process "explorer.exe"
