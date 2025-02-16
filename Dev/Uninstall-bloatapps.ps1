$bloatpackages = @('Copilot', 'Dev Home', 'Game Bar', 'Game Speech Window', 'Feedback hub', 'Microsoft.BingSearch', 'LinkedIn', 'LinkedInforWindows', 'Microsoft Clipchamp', 'Microsoft News', 'Microsoft OneDrive', 'Microsoft To Do', 'MSN Weather', 'Media Player', 'Outlook', 'OneDrive', 'Power Automate', 'Quick Assist', 'Solitaire & Casual Games', 'Sound Recorder', 'Sticky Notes', 'Teams', 'Windows Clock', 'Xbox TCUI', 'Xbox Identity Provider', 'xbox', 'Microsoft 365 Copilot', 'Microsoft 365 (Office)')
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
    "No installed $($app) package found."
  }
}
Write-host ""
#Uninstall Appx Packages
$appxpackages = @(
  'MicrosoftWindows.CrossDevice',
  'Microsoft.ZuneMusic',
  'Microsoft.YourPhone',
  'Microsoft.XboxGamingOverlay',
  'LinkedIn',
  'LinkedInforWindows',
  'Microsoft.GetHelp',
  'Microsoft.Windows.DevHome',
  "Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe!Microsoft.MicrosoftOfficeHub",
  "Microsoft.Copilot_8wekyb3d8bbwe!App",
  "Microsoft.GetHelp_8wekyb3d8bbwe!App",
  "Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe!PAD.Console",
  "Microsoft.BingWeather_8wekyb3d8bbwe!App",
  "Microsoft.BingSearch"
  "*WebExperience*"
)

foreach ($appx in ($appxpackages | Sort-object)) {
  Write-host "Trying to uninstalling $appx, Please Wait."
  Get-AppxPackage $appx -AllUsers -Verbose | Remove-AppxPackage -AllUsers -Verbose -ErrorAction SilentlyContinue
  Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$appx*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-host ""
Write-host "Disabling Copilot and recall" -ForegroundColor Yellow
$features = @("Microsoft.Windows.Copilot", "Recall")

foreach ($feature in $features) {
  Write-host "Checking for: $feature"
  $recallenabled = DISM /Online /Get-FeatureInfo /FeatureName:$feature

  # Capture only the relevant lines (Feature Name and State)
  $relevantLines = $recallenabled | Select-String -Pattern "^Feature Name|^State"

  # Convert the output to a hashtable (handling the colon with spaces)
  $featureInfo = @{}
  foreach ($line in $relevantLines) {
    if ($line -match "^(.*?)\s*:\s*(.*)$") {
      # Capture name and value
      $name = $Matches[1].Trim()
      $value = $Matches[2].Trim()
      $featureInfo[$name] = $value
    }
  }

  
  #Check if the key exists before attempting to access it
  if ($featureInfo.ContainsKey("State")) {
    $state = $featureInfo["State"]
    Write-Host "`t$feature State: $state"
  }
  else {
    Write-Host "State information not found in DISM output."
  }

  If ($state = "Enabled") {
    try {
      DISM /Online /Disable-Feature /FeatureName:$feature
    }
    Catch {
      
    }
  }
}


write-host ""
Write-Host "Finished processing Bloatware and Tweaks." -ForegroundColor Green