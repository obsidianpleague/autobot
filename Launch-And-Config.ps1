$ErrorActionPreference = "Stop"
$WshShell = New-Object -ComObject WScript.Shell

$AppPath_System = "C:\Program Files\autobot-jamb-browser-64\autobot-jamb-browser-64.exe"
$AppPath_User   = "$env:LOCALAPPDATA\Programs\autobot-jamb-browser-64\autobot-jamb-browser-64.exe"
$TargetExe = ""

if (Test-Path $AppPath_System) { $TargetExe = $AppPath_System }
elseif (Test-Path $AppPath_User) { $TargetExe = $AppPath_User }

if (-not $TargetExe) { exit }

$ProcessName = [System.IO.Path]::GetFileNameWithoutExtension($TargetExe)
$Proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

if (-not $Proc) {
    Start-Process -FilePath $TargetExe
    $Timeout = 10
    $Timer = 0
    do {
        Start-Sleep -Seconds 1
        $Proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        $Timer++
    } while ((-not $Proc) -and ($Timer -lt $Timeout))
}

if ($Proc) {
    $Timeout = 20
    $Timer = 0
    do {
        Start-Sleep -Seconds 1
        $Proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        $Timer++
    } while (($Proc -and -not $Proc.MainWindowHandle) -and ($Timer -lt $Timeout))
}

Start-Sleep -Seconds 2

try {
    Set-Clipboard -Value "192.168.0.1"
} catch {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Clipboard]::SetText("192.168.0.1")
    } catch {}
}

 # Ensure window is actually focused
$Activated = $false
$FocusAttempts = 0
$TargetTitle = "ENTER SERVER URL"

while (-not $Activated -and $FocusAttempts -lt 10) {
    # Try specific modal title first
    $Activated = $WshShell.AppActivate($TargetTitle)
    
    # Fallback to process name if specific title fails
    if (-not $Activated) {
        $Activated = $WshShell.AppActivate($ProcessName)
    }
    
    if ($Activated) { break }
    Start-Sleep -Milliseconds 500
    $FocusAttempts++
}

if ($Activated) {
    Start-Sleep -Milliseconds 500
    $WshShell.SendKeys("^a")
    Start-Sleep -Milliseconds 500
    $WshShell.SendKeys("^v")
    Start-Sleep -Milliseconds 500
    $WshShell.SendKeys("{ENTER}")
} else {
    # If we still can't find it, log a warning (silent in this context, but good for debugging)
    # exit
    exit
}
