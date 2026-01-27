@echo off
TITLE JAMB AUTOBOT - Generate Target Lists
COLOR 0B

echo Generating Target Lists...
echo.

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "Generate-Center1.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "Generate-Center2.ps1"

echo.
echo SUCCESS! Target lists updated.
pause
