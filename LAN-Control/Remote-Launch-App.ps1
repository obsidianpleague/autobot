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
    Write-Output "FAIL:Application not found"
    return
}

$TargetUser = $null

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
    Write-Output "FAIL:No active user session"
    return
}

$TaskName = "AutoBot_Remote_Launch"

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$WrapperPath = "C:\Windows\Temp\AutoBot_Launcher.ps1"

@"
Start-Process -FilePath "$TargetExe"
Start-Sleep -Seconds 10
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
"@ | Set-Content -Path $WrapperPath -Force

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WrapperPath`""
$Principal = New-ScheduledTaskPrincipal -UserId $TargetUser -LogonType Interactive -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

Start-ScheduledTask -TaskName $TaskName

Start-Sleep -Seconds 15

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $WrapperPath -Force -ErrorAction SilentlyContinue

Write-Output "OK"
