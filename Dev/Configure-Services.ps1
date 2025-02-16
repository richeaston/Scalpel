# Get the current script execution directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Read the JSON file from the current script execution directory
$services = Get-Content -Path "$scriptDir\Services.json" | ConvertFrom-Json

# Loop through each service in the JSON file
foreach ($service in $services) {
    try {
        # Check if the service exists
        if (Get-Service -Name $service.ServiceName -ErrorAction SilentlyContinue) {
            # Check if the service is running
            if ((Get-Service -Name $service.ServiceName).Status -eq "Running") {
                # Stop the service forcefully
                Write-Host "Stopping service $($service.ServiceName)"
                Stop-Service -Name $service.ServiceName -Force -ErrorAction SilentlyContinue
            }

            # Translate the numeric StartType value
            switch ($service.StartType) {
                0 { $startType = "Boot" }
                1 { $startType = "System" }
                2 { $startType = "Automatic" }
                3 { $startType = "Manual" }
                4 { $startType = "Disabled" }
                default { $startType = "Unknown" }
            }

            # Set the service StartType
            Write-Host "Setting service $($service.ServiceName) to $startType"
            Set-Service -Name $service.ServiceName -StartupType $startType -ErrorAction SilentlyContinue
        } else {
            # Service does not exist
            Write-Host "Service $($service.ServiceName) does not exist"
        }
    }
    catch {
        # Write the error message to the console
        Write-Host "Error configuring service $($service.ServiceName): $($_.Exception.Message)"
    }
}