$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Enable LAN Deployment"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  LAN DEPLOYMENT SETUP" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Write-Host "[1/6] Configuring WinRM..." -ForegroundColor Cyan
winrm quickconfig -quiet -force 2>$null | Out-Null
Write-Host "       Done"

Write-Host "[2/6] Adding firewall rules..." -ForegroundColor Cyan
netsh advfirewall firewall delete rule name="WinRM-HTTP" 2>$null | Out-Null
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985 2>$null | Out-Null
netsh advfirewall firewall delete rule name="ICMP-Allow" 2>$null | Out-Null
netsh advfirewall firewall add rule name="ICMP-Allow" protocol=icmpv4:8,any dir=in action=allow 2>$null | Out-Null
Write-Host "       Done"

Write-Host "[3/6] Setting LocalAccountTokenFilterPolicy..." -ForegroundColor Cyan
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f 2>$null | Out-Null
Write-Host "       Done"

Write-Host "[4/6] Creating DeployAdmin account..." -ForegroundColor Cyan
$Password = ConvertTo-SecureString "Jamb123!" -AsPlainText -Force
$Existing = Get-LocalUser -Name "DeployAdmin" -ErrorAction SilentlyContinue
if ($Existing) {
    Set-LocalUser -Name "DeployAdmin" -Password $Password -ErrorAction SilentlyContinue
    Write-Host "       Done (account already existed, password reset)"
} else {
    New-LocalUser -Name "DeployAdmin" -Password $Password -FullName "Deploy Admin" -PasswordNeverExpires -ErrorAction Stop | Out-Null
    Write-Host "       Done (account created)"
}

Write-Host "[5/6] Adding to Administrators group..." -ForegroundColor Cyan
Add-LocalGroupMember -Group "Administrators" -Member "DeployAdmin" -ErrorAction SilentlyContinue
Enable-LocalUser -Name "DeployAdmin" -ErrorAction SilentlyContinue
Write-Host "       Done"

Write-Host "[6/6] Setting password never expires..." -ForegroundColor Cyan
Set-LocalUser -Name "DeployAdmin" -PasswordNeverExpires $true -ErrorAction SilentlyContinue
Write-Host "       Done"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
$Check = Get-LocalUser -Name "DeployAdmin" -ErrorAction SilentlyContinue
if ($Check) {
    Write-Host "  VERIFIED: DeployAdmin account exists" -ForegroundColor Green
} else {
    Write-Host "  ERROR: DeployAdmin account NOT found" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Credentials:" -ForegroundColor White
Write-Host "    Username: DeployAdmin" -ForegroundColor White
Write-Host "    Password: Jamb123!" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
