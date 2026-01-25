@echo off

:: Auto-Elevation
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

if not "%1"=="hidden" (
    start /min "" "%~f0" hidden
    exit
)

cd /d "%~dp0"

IF EXIST "%LOCALAPPDATA%\Programs\autobot-jamb-browser\autobot-jamb-browser.exe" (
    ECHO Already installed on this PC. >> install_log.txt
    ECHO %COMPUTERNAME% - SKIPPED [already installed] - %DATE% %TIME% >> install_log.txt
    EXIT
)

IF EXIST "C:\Program Files\autobot-jamb-browser\autobot-jamb-browser.exe" (
    ECHO Already installed on this PC. >> install_log.txt
    ECHO %COMPUTERNAME% - SKIPPED [already installed] - %DATE% %TIME% >> install_log.txt
    EXIT
)

SET "INSTALLER="
IF EXIST "%~dp0autobot-jamb-browser Setup_64bit.exe" SET "INSTALLER=%~dp0autobot-jamb-browser Setup_64bit.exe"
IF EXIST "%~dp0autobot.exe" SET "INSTALLER=%~dp0autobot.exe"

IF "%INSTALLER%"=="" (
    ECHO %COMPUTERNAME% - ERROR: Installer not found - %DATE% %TIME% >> install_log.txt
    EXIT /B 1
)

ECHO.
ECHO Installing JAMB AUTOBOT Browser...
ECHO Please wait...
"%INSTALLER%" /ALLUSERS=1 /S

timeout /t 10 /nobreak >nul

powershell -WindowStyle Hidden -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('C:\Users\Public\Desktop\autobot-jamb-browser.lnk'); $ExePath = \"$env:LOCALAPPDATA\Programs\autobot-jamb-browser\autobot-jamb-browser.exe\"; if (Test-Path $ExePath) { $Shortcut.TargetPath = $ExePath; $Shortcut.Save() } else { $AltPath = 'C:\Program Files\autobot-jamb-browser\autobot-jamb-browser.exe'; if (Test-Path $AltPath) { $Shortcut.TargetPath = $AltPath; $Shortcut.Save() } }"

copy "C:\Users\Public\Desktop\autobot-jamb-browser.lnk" "C:\Users\Default\Desktop\" /Y >nul 2>&1

netsh advfirewall set allprofiles state off

powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0

powershell -WindowStyle Hidden -Command "Add-Type -AssemblyName Microsoft.VisualBasic; $IP = [Microsoft.VisualBasic.Interaction]::InputBox('Enter Static IP Address (Leave empty to skip):', 'IP Configuration'); if ($IP) { $Subnet = [Microsoft.VisualBasic.Interaction]::InputBox('Enter Subnet Mask:', 'IP Configuration', '255.255.255.0'); $Adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1; if ($Adapter) { netsh interface ip set address \"$($Adapter.Name)\" static $IP $Subnet } }"

ECHO %COMPUTERNAME% - SUCCESS - %DATE% %TIME% >> "%~dp0install_log.txt"

powershell -WindowStyle Hidden -Command "[System.Media.SystemSounds]::Exclamation.Play(); Start-Sleep -Milliseconds 1000"

msg * "JAMB AUTOBOT installed successfully!" /TIME:3 2>nul

EXIT
