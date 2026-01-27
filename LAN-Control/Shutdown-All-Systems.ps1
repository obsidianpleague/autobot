Param(
    [PSCredential]$Credential,
    [int]$DelaySeconds = 0
)

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\Shutdown_Log.csv"


function Write-Log {
    Param($Target, $Status, $Message)
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($Status -eq "SUCCESS") { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Green }
    elseif ($Status -eq "ERROR")   { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Red }
    else                           { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Yellow }

    [PSCustomObject]@{ Timestamp = $Date; Target = $Target; Status = $Status; Message = $Message } | Export-Csv -Path $LogFile -Append -NoTypeInformation
}


Write-Host "=========================================" -ForegroundColor Red
Write-Host "   EMERGENCY SHUTDOWN CONTROLLER" -ForegroundColor Red
Write-Host "========================================="
Write-Host "1. Shutdown CENTER 1 (192.168.x.x)"
Write-Host "2. Shutdown CENTER 2 (172.16.x.x)"
Write-Host "Q. Cancel"
$CenterChoice = Read-Host "Select Center to Shutdown"

switch ($CenterChoice) {
    "1" { $TargetList = "$PSScriptRoot\Center1_Targets.txt" }
    "2" { $TargetList = "$PSScriptRoot\Center2_Targets.txt" }
    "Q" { exit }
    Default { Write-Warning "Invalid selection."; exit }
}

if (-not (Test-Path $TargetList)) {
    Write-Error "Target list not found ($TargetList). Please run Generate-Center1/2.ps1 first."
    exit
}

if (-not $Credential) {
    Write-Host "Enter Admin Credentials..." -ForegroundColor Yellow
    $Credential = Get-Credential
}


$AllTargets = Get-Content $TargetList | Where-Object { -not $_.StartsWith("#") -and $_.Trim() -ne "" }
$OnlineTargets = @()

Write-Host "Scanning $($AllTargets.Count) targets..." -ForegroundColor Cyan
foreach ($Target in $AllTargets) {
    if (Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        $OnlineTargets += $Target
        Write-Host "." -NoNewline -ForegroundColor Green
    }
}
Write-Host ""
Write-Host "Online: $($OnlineTargets.Count) / $($AllTargets.Count)" -ForegroundColor Cyan

if ($OnlineTargets.Count -eq 0) { Write-Warning "No targets online."; exit }


Write-Host "SHUTTING DOWN $($OnlineTargets.Count) SYSTEMS..." -ForegroundColor Red
Start-Sleep -Seconds 2

$ScriptBlock = {
    Param([int]$Delay)
    Start-Process "shutdown.exe" -ArgumentList "/s /f /t $Delay" -Wait -NoNewWindow
}

try {
    $Results = Invoke-Command -ComputerName $OnlineTargets -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $DelaySeconds -ThrottleLimit 50 -ErrorVariable ExecError
    

    $SuccessHosts = if ($Results) { $Results.PSComputerName } else { @() }
    

    $FailedHosts = $OnlineTargets | Where-Object { $SuccessHosts -notcontains $_ }
    
    foreach ($Failed in $FailedHosts) {
         Write-Log -Target $Failed -Status "ERROR" -Message "Shutdown Failed (Access Denied?)"
         Write-Host "   ! FAILED: $Failed - Check Admin Rights / Run ENABLE-LAN-DEPLOY.bat" -ForegroundColor Red
    }

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Shutdown command execution complete." -ForegroundColor Cyan
Pause
