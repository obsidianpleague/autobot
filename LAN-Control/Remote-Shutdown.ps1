Param(
    [int]$DelaySeconds = 0
)
$ErrorActionPreference = "Stop"


Start-Process "shutdown.exe" -ArgumentList "/s /f /t $DelaySeconds" -Wait -NoNewWindow
