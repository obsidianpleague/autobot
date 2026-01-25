Param(
    [int]$DelaySeconds = 30
)

$ErrorActionPreference = "Stop"

try {
    msg * /TIME:10 "System is shutting down in $DelaySeconds seconds by IT Administrator."
} catch {
    Write-Warning "Failed to send message (msg.exe might be missing)."
}

$Comment = "Authorized Remote Shutdown by JAMB IT Admin"
Start-Process "shutdown.exe" -ArgumentList "/s /f /t $DelaySeconds /c `"$Comment`"" -Wait -NoNewWindow

Write-Host "Shutdown initiated with ${DelaySeconds}s delay."
