$ErrorActionPreference = "Stop"

$AppName = "autobot-jamb-browser-64"
$ExeName = "autobot-jamb-browser-64.exe"

$AppPath_System = "C:\Program Files\$AppName\$ExeName"
$TargetExe = ""

if (Test-Path $AppPath_System) {
    $TargetExe = $AppPath_System
} else {
    $UserProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notin @("Public", "Default", "Default User", "All Users", "DeployAdmin")
    }
    foreach ($Profile in $UserProfiles) {
        $UserAppPath = Join-Path $Profile.FullName "AppData\Local\Programs\$AppName\$ExeName"
        if (Test-Path $UserAppPath) {
            $TargetExe = $UserAppPath
            break
        }
    }
}

if (-not $TargetExe) {
    Write-Error "Application not found in system or any user profile."
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

Write-Host "Launching from: $TargetExe"
Write-Host "Creating interactive task for $TargetUser..."

Start-Process -FilePath "schtasks.exe" -ArgumentList "/Create /TN $TaskName /TR `"`"$TargetExe`"`" /SC ONCE /ST 00:00 /IT /RU $TargetUser /RP `"`" /F /RL HIGHEST" -Wait -NoNewWindow

Start-Process -FilePath "schtasks.exe" -ArgumentList "/Run /TN $TaskName" -Wait -NoNewWindow

Start-Sleep -Seconds 5
Start-Process -FilePath "schtasks.exe" -ArgumentList "/Delete /TN $TaskName /F" -Wait -NoNewWindow

Write-Host "Launch command sent."
