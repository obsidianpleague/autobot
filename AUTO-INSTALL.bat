@echo off

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

ECHO %COMPUTERNAME% - SUCCESS - %DATE% %TIME% >> "%~dp0install_log.txt"

powershell -WindowStyle Hidden -Command "[System.Media.SystemSounds]::Exclamation.Play(); Start-Sleep -Milliseconds 1000"

msg * "JAMB AUTOBOT installed successfully!" /TIME:3 2>nul

EXIT
