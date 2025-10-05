param(
    [Parameter(Mandatory = $true)]
    [string]$Folder
)

Write-Host "Target folder is: $Folder"

$Action = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Tools\AppendPng.ps1" -Folder "' + $Folder + '"'

# Remove any old tasks first (ignore errors)
schtasks /Delete /TN "Append PNG - Every5Min" /F 2>$null
schtasks /Delete /TN "Append PNG - AtStartup" /F 2>$null

# Create the two tasks
schtasks /Create /TN "Append PNG - Every5Min" /SC MINUTE /MO 5 /TR "$Action" /RL HIGHEST
schtasks /Create /TN "Append PNG - AtStartup" /SC ONSTART /TR "$Action" /RL HIGHEST

# Show confirmation
schtasks /Query /TN "Append PNG - Every5Min"
schtasks /Query /TN "Append PNG - AtStartup"

Write-Host "Scheduled tasks created successfully."
Write-Host "They will run at startup and every 5 minutes."
