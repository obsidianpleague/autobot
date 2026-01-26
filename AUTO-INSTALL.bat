@echo off

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

IF EXIST "%LOCALAPPDATA%\Programs\autobot-jamb-browser-64\autobot-jamb-browser-64.exe" (
    ECHO Already installed on this PC. >> install_log.txt
    ECHO %COMPUTERNAME% - SKIPPED [already installed] - %DATE% %TIME% >> install_log.txt
    EXIT
)

IF EXIST "C:\Program Files\autobot-jamb-browser-64\autobot-jamb-browser-64.exe" (
    ECHO Already installed on this PC. >> install_log.txt
    ECHO %COMPUTERNAME% - SKIPPED [already installed] - %DATE% %TIME% >> install_log.txt
    EXIT
)

SET "INSTALLER="
IF EXIST "%~dp0autobot-jamb-browser-2025.exe" SET "INSTALLER=%~dp0autobot-jamb-browser-2025.exe"
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

ECHO Configuring System Settings...
netsh advfirewall set allprofiles state off
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0

ECHO Configuring IP Address (Check Popup)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-AutoIP.ps1"

ECHO %COMPUTERNAME% - SUCCESS - %DATE% %TIME% >> "%~dp0install_log.txt"

ECHO Launching Application & Automating Setup...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-And-Config.ps1"

EXIT
