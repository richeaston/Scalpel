function Pin-App {    param(
        [string]$appname,
        [switch]$unpin
    )
    try{
        if ($unpin.IsPresent){
            ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Von "Taskbar" lösen|Unpin from Taskbar'} | %{$_.DoIt()}
            return "App '$appname' unpinned from Taskbar"
        }else{
            ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'An "Taskbar" anheften|Pin to Taskbar'} | %{$_.DoIt()}
            return "App '$appname' pinned to Taskbar"
        }
    }catch{
        Write-Error "Error Pinning/Unpinning App! (App-Name correct?)"
    }
}

Pin-App "Mail" -unpin
Pin-App "Microsoft Store" -unpin
Pin-App "Cortana" -unpin
Pin-App "Excel"
Pin-App "Outlook"
