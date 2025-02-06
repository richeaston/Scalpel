$bloatpackages = @('Copilot','Dev Home','Game Bar','Game Speech Window','Feedback hub','Microsoft Bing Search','LinkedIn','Microsoft Clipchamp','Microsoft News','Microsoft OneDrive','Microsoft To Do','MSN Weather','Media Player','Outlook','OneDrive','Power Automate','Quick Assist','Solitaire & Casual Games','Sound Recorder','Sticky Notes','Teams','Windows Clock','Xbox TCUI', 'Xbox Identity Provider','xbox','Microsoft 365 Copilot''Microsoft 365 (Office)')

#uninstall via winget
foreach ($app in ($bloatpackages | sort-object)) {
    try {
        Winget uninstall $app --silent --force --purge --verbose
    }
    catch {
        "No installed package found matching input criteria."
    }
}

#Uninstall Appx Packages
$appxpackages = @('MicrosoftWindows.CrossDevice', 'Microsoft.MicrosoftEdge.Stable', 'Microsoft.ZuneMusic', 'Microsoft.YourPhone', 'Microsoft.XboxGamingOverlay', 'Microsoft.GetHelp', 'Microsoft.Windows.DevHome' )
foreach ($appx in ($appxpackages | Sort-object)) {
    Write-host "Trying to uninstalling $appx, Please Wait."
    Get-AppxPackage $appx -AllUsers -Verbose | Remove-AppxPackage -AllUsers -Verbose -ErrorAction Ignore
}

write-host ""
Write-Host "Finished processing Bloatware." -ForegroundColor Green