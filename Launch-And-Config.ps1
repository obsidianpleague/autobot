$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
$WshShell = New-Object -ComObject WScript.Shell

$AppPath_System = "C:\Program Files\autobot-jamb-browser\autobot-jamb-browser.exe"
$AppPath_User   = "$env:LOCALAPPDATA\Programs\autobot-jamb-browser\autobot-jamb-browser.exe"
$TargetExe = ""

if (Test-Path $AppPath_System) { $TargetExe = $AppPath_System }
elseif (Test-Path $AppPath_User) { $TargetExe = $AppPath_User }

if (-not $TargetExe) { exit }

Start-Process -FilePath $TargetExe

Start-Sleep -Seconds 8

try {
    $WshShell.AppActivate("autobot-jamb-browser")
} catch {}

$WshShell.SendKeys("^a")
Start-Sleep -Milliseconds 200
$WshShell.SendKeys("^v")
Start-Sleep -Milliseconds 500
$WshShell.SendKeys("{ENTER}")
