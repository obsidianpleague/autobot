$ErrorActionPreference = "SilentlyContinue"

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

$TargetUser = $null
$SessionId = $null

try {
    $quser = quser 2>&1
    foreach ($Line in $quser) {
        if ($Line -match "Active" -or $Line -match "Console") {
            $Parts = $Line.Trim() -replace '\s{2,}', ',' -split ','
            $TargetUser = $Parts[0].Replace(">", "").Trim()
            break
        }
    }
} catch {}

if (-not $TargetUser) {
    Write-Warning "No active user session found. Cannot launch GUI app."
    return
}

Write-Host "Detected Active User: $TargetUser"
Write-Host "Application Path: $TargetExe"

$TaskName = "AutoBot_Remote_Launch"

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$Action = New-ScheduledTaskAction -Execute $TargetExe
$Principal = New-ScheduledTaskPrincipal -UserId $TargetUser -LogonType Interactive -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

Write-Host "Starting application in $TargetUser's session..."
Start-ScheduledTask -TaskName $TaskName

Start-Sleep -Seconds 3

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "Launch command sent for user: $TargetUser"
