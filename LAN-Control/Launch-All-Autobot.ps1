Param(
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\Launch_Log.csv"


function Write-Log {
    Param($Target, $Status, $Message)
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($Status -eq "SUCCESS") { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Green }
    elseif ($Status -eq "ERROR")   { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Red }
    else                           { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Yellow }

    [PSCustomObject]@{ Timestamp = $Date; Target = $Target; Status = $Status; Message = $Message } | Export-Csv -Path $LogFile -Append -NoTypeInformation
}


Write-Host "=========================================" -ForegroundColor Green
Write-Host "   MASS LAUNCH CONTROLLER" -ForegroundColor Green
Write-Host "========================================="
Write-Host "1. Launch on CENTER 1 (192.168.x.x)"
Write-Host "2. Launch on CENTER 2 (172.16.x.x)"
Write-Host "Q. Cancel"
$CenterChoice = Read-Host "Select Center"

switch ($CenterChoice) {
    "1" { $TargetList = "$PSScriptRoot\Center1_Targets.txt" }
    "2" { $TargetList = "$PSScriptRoot\Center2_Targets.txt" }
    "Q" { exit }
    Default { Write-Warning "Invalid selection."; exit }
}

if (-not (Test-Path $TargetList)) {
    Write-Error "Target list not found ($TargetList)."
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


Write-Host "Launching App on $($OnlineTargets.Count) systems..." -ForegroundColor Green
$ScriptBlock = [ScriptBlock]::Create((Get-Content "$PSScriptRoot\Remote-Launch-App.ps1" -Raw))

try {
    $Results = Invoke-Command -ComputerName $OnlineTargets -Credential $Credential -ScriptBlock $ScriptBlock -ThrottleLimit 50
    

    $SuccessHosts = if ($Results) { $Results.PSComputerName } else { @() }
    

    $FailedHosts = $OnlineTargets | Where-Object { $SuccessHosts -notcontains $_ }
    
    foreach ($Failed in $FailedHosts) {
         Write-Log -Target $Failed -Status "ERROR" -Message "Launch Failed (Access Denied?)"
         Write-Host "   ! FAILED: $Failed - Check Admin Rights / Run ENABLE-LAN-DEPLOY.bat" -ForegroundColor Red
    }
    
    if ($Results) {
        foreach ($Res in $Results) { Write-Log -Target $Res.PSComputerName -Status "SUCCESS" -Message "Launch Sent" }
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Execution complete." -ForegroundColor Cyan
Pause
