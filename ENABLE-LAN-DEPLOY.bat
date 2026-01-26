@echo off
TITLE JAMB AUTOBOT - Enable LAN Deployment
COLOR 0A

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

ECHO Enabling LAN Deployment... (Please Wait)

winrm quickconfig -quiet -force >nul 2>&1
netsh advfirewall set allprofiles state off >nul 2>&1
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul 2>&1

net user DeployAdmin Jamb123! /add >nul 2>&1
net localgroup Administrators DeployAdmin /add >nul 2>&1
net user DeployAdmin /active:yes >nul 2>&1
wmic useraccount where "Name='DeployAdmin'" set PasswordExpires=FALSE >nul 2>&1

ECHO.
ECHO SUCCESS! 
ECHO Admin: DeployAdmin / Jamb123!
ECHO.
PAUSE
