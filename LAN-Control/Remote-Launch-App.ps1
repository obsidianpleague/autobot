$ErrorActionPreference = "Stop"

$AppPath_System = "C:\Program Files\autobot-jamb-browser\autobot-jamb-browser.exe"
$AppPath_User   = "$env:LOCALAPPDATA\Programs\autobot-jamb-browser\autobot-jamb-browser.exe"

$TargetExe = ""
if (Test-Path $AppPath_System) { $TargetExe = $AppPath_System }
elseif (Test-Path $AppPath_User) { $TargetExe = $AppPath_User }

if (-not $TargetExe) {
    Write-Error "Application not found in standard locations."
    return
}

try {
    $quser = quser 2>&1
    $ActiveSession = $quser | Where-Object { $_ -match "Active" -or $_ -match "Console" } | Select-Object -First 1
    
    if (-not $ActiveSession) {
        Write-Warning "No active user session found. Cannot launch GUI app."
        return
    }

    $TargetUser = $ActiveSession.Trim().Split(" ")[0]
    $TargetUser = $TargetUser.Replace(">", "")
    
    Write-Host "Detected Active User: $TargetUser"
}
catch {
    Write-Warning "Failed to query users. Is this a workstation?"
    return
}

$TaskName = "AutoBot_Remote_Launch"
$Action = New-ScheduledTaskAction -Execute $TargetExe
$Trigger = New-ScheduledTaskTrigger -Once -At 00:00

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Attempting to create interactive task for $TargetUser..."

Start-Process -FilePath "schtasks.exe" -ArgumentList "/Create /TN $TaskName /TR `"`"$TargetExe`"`" /SC ONCE /ST 00:00 /IT /RU $TargetUser /RP `"`" /F /RL HIGHEST" -Wait -NoNewWindow

Start-Process -FilePath "schtasks.exe" -ArgumentList "/Run /TN $TaskName" -Wait -NoNewWindow

Start-Sleep -Seconds 5
Start-Process -FilePath "schtasks.exe" -ArgumentList "/Delete /TN $TaskName /F" -Wait -NoNewWindow

Write-Host "Launch command sent."
