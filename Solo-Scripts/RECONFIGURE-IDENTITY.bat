@echo off
setlocal EnableDelayedExpansion

title MAC ADDRESS CHANGE
color 0E

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

echo =========================================
echo   MAC ADDRESS CHANGE - PLUG ^& PLAY
echo =========================================
echo.
echo This will change the MAC address,
echo then IMMEDIATELY RESTART the computer.
echo.
echo Press any key to continue or close this window to cancel...
pause >nul

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Reconfigure-Identity.ps1"

if not exist "%PS_SCRIPT%" (
    color 0C
    echo ERROR: Reconfigure-Identity.ps1 not found!
    pause
    exit /b 1
)

echo.
echo Running identity reconfiguration...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

if %ERRORLEVEL% neq 0 (
    color 0C
    echo.
    echo ERROR: Reconfiguration failed! Check the log file.
    pause
    exit /b 1
)
