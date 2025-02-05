# Define the list of apps to remove
$AppsToRemove = @(
    "Clipchamp.Clipchamp",
    "Microsoft.3DBuilder",
    "Microsoft.549981C3F5F10",   # Cortana app
    "Microsoft.BingFinance",
    "Microsoft.BingFoodAndDrink",
    "Microsoft.BingHealthAndFitness",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingTranslator",
    "Microsoft.BingTravel",
    "Microsoft.BingWeather",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftJournal",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftPowerBIForWindows",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.NetworkSpeedTest",
    "Microsoft.News",
    "Microsoft.Office.OneNote",
    "Microsoft.Office.Sway",
    "Microsoft.OneConnect",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.Todos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.XboxApp",   # Old Xbox Console Companion App, no longer supported
    "Microsoft.ZuneVideo",
    "MicrosoftCorporationII.MicrosoftFamily",   # Family Safety App
    "MicrosoftCorporationII.QuickAssist",
    "MicrosoftTeams",   # Old MS Teams personal (MS Store)
    "MSTeams",   # New MS Teams app
    "ACGMediaPlayer",
    "ActiproSoftwareLLC",
    "AdobeSystemsIncorporated.AdobePhotoshopExpress",
    "Amazon.com.Amazon",
    "Asphalt8Airborne",
    "AutodeskSketchBook",
    "CaesarsSlotsFreeCasino",
    "COOKINGFEVER",
    "CyberLinkMediaSuiteEssentials",
    "DisneyMagicKingdoms",
    "Disney",
    "DrawboardPDF",
    "Duolingo-LearnLanguagesforFree",
    "EclipseManager",
    "Facebook",
    "FarmVille2CountryEscape",
    "fitbit",
    "Flipboard",
    "HiddenCity",
    "HULULLC.HULUPLUS",
    "iHeartRadio",
    "Instagram",
    "king.com.BubbleWitch3Saga",
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",
    "LinkedInforWindows",
    "OneCalendar",
    "PicsArt-PhotoStudio",
    "Plex",
    "PolarrPhotoEditorAcademicEdition",
    "Royal Revolt",
    "Shazam",
    "Sidia.LiveWallpaper",
    "Spotify",
    "TikTok",
    "TuneInRadio",
    "Twitter",
    "Viber",
    "WinZipUniversal",
    "Wunderlist",
    "XING"
)

# Loop through each app in the list
foreach ($App in $AppsToRemove) {
    # Check if the app is installed via Appx
    if (Get-AppxPackage -Name $App -ErrorAction SilentlyContinue) {
        Write-Host "Removing Appx Package: $App"
        try {
            Remove-AppxPackage -Name $App -ErrorAction SilentlyContinue
        }
        Catch {
            
        }
    } else {
        # Check if the app is installed traditionally (via registry)
        $UninstallString = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $App } | Select-Object -ExpandProperty UninstallString

        if ($UninstallString) {
            Write-Host "Uninstalling: $App"
            # Use msiexec.exe to uninstall
            Start-Process "msiexec.exe" -ArgumentList "/x $UninstallString /qn" -Wait -ErrorAction SilentlyContinue
        } else {
            Write-Host "App not found: $App"
        }
    }
}

Write-Host "Finished processing app list."