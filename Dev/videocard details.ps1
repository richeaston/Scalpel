$ComputerVideoCard = Get-WmiObject Win32_VideoController 
    $Output = New-Object -TypeName PSObject
    Foreach ($Card in $ComputerVideoCard)
        {
        $Output | Add-Member NoteProperty "$($Card.DeviceID)_Name" $Card.Name
        #$Output | Add-Member NoteProperty "$($Card.DeviceID)_Description" $Card.Description #Probably not needed. Seems to just echo the name. Left here in case I'm wrong!
        $Output | Add-Member NoteProperty "$($Card.DeviceID)_Vendor" $Card.AdapterCompatibility
        $Output | Add-Member NoteProperty "$($Card.DeviceID)_PNPDeviceID" $Card.PNPDeviceID
        $Output | Add-Member NoteProperty "$($Card.DeviceID)_DriverVersion" $Card.DriverVersion
        $Output | Add-Member NoteProperty "$($Card.DeviceID)_VideoMode" $Card.VideoModeDescription
        }
    $Output