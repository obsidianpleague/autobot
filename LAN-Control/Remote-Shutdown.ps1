Param(
    [int]$DelaySeconds = 0
)

Start-Process "shutdown.exe" -ArgumentList "/s /f /t $DelaySeconds" -NoNewWindow
