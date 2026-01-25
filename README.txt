# JAMB AUTOBOT - USB Auto-Installer

## What's on this USB

| File | Purpose |
|------|---------|
| `AUTO-INSTALL.bat` | Auto-installer (runs automatically or double-click) |
| `autorun.inf` | Triggers auto-run on insert |
| `autobot-jamb-browser Setup_64bit.exe` | The installer (YOU need to add this!) |
| `install_log.txt` | Log of all installed PCs (created automatically) |

## How to Use

### Setup (Once):
1. Copy ALL files from this folder to root of USB drive
2. Add your `autobot-jamb-browser Setup_64bit.exe` to the USB

### Install on Each PC:
1. Plug in USB
2. If autorun works: Installation starts automatically!
3. If autorun doesn't work: Double-click `AUTO-INSTALL.bat`
4. Wait for beep sound = Done!
5. Unplug USB, move to next PC

## Features
- ✅ Fully silent installation
- ✅ Skips already-installed PCs
- ✅ Creates desktop shortcut for ALL users
- ✅ Logs all installations to `install_log.txt`
- ✅ Beeps when complete

## Note About Autorun
Windows 10/11 disables USB autorun by default for security.
If it doesn't auto-run, just double-click `AUTO-INSTALL.bat`.
