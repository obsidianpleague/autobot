@echo off
TITLE JAMB AUTOBOT - Enable LAN Deployment
COLOR 0A

ECHO =========================================
ECHO   ENABLE LAN DEPLOYMENT (Run on Target PCs)
ECHO =========================================
ECHO.
ECHO This script prepares this computer for remote deployment.
ECHO It creates a temporary admin account so you can
ECHO deploy software from your main computer.
ECHO.
ECHO Press any key to continue...
PAUSE >nul

ECHO.
ECHO [1/3] Enabling Remote Management...
winrm quickconfig -quiet -force

ECHO [2/3] Configuring Security Settings...
netsh advfirewall set allprofiles state off
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

ECHO [3/3] Creating Deployment Admin Account...
ECHO User: DeployAdmin
ECHO Pass: Jamb123!
net user DeployAdmin Jamb123! /add 2>nul
net localgroup Administrators DeployAdmin /add 2>nul
net user DeployAdmin /active:yes 2>nul
wmic useraccount where "Name='DeployAdmin'" set PasswordExpires=FALSE

ECHO.
ECHO =========================================
ECHO   READY FOR LAN DEPLOYMENT!
ECHO =========================================
ECHO.
ECHO You can now deploy to this PC from your main computer
ECHO using the credentials:
ECHO   User: DeployAdmin
ECHO   Pass: Jamb123!
ECHO.
PAUSE
