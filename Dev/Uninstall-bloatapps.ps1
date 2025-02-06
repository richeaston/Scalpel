$bloatpackages = @('*Copilot*','*Dev Home*','*Game Bar*','*Game Speech Window*','*Microsoft 365 (Office)*','*Microsoft Bing Search*','*Microsoft Clipchamp*','*Microsoft News*','*Microsoft OneDrive*','*Microsoft To Do*','*MSN Weather*','*OneDrive*','*Power Automate*','*Quick Assist*','*Solitaire & Casual Games*','*Xbox*')

foreach ($app in $bloatpackages) {
    Winget uninstall $app --silent --force --purge -- verbose --ignore-warnings
}

Write-Host "Finished processing app list."