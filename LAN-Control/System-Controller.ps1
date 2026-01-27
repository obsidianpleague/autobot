Param(
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\Controller_Log.csv"


function Write-Log {
    Param($Target, $Status, $Message)
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    

    if ($Status -eq "SUCCESS") { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Green }
    elseif ($Status -eq "ERROR")   { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Red }
    elseif ($Status -eq "WARNING") { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Yellow }
    else                           { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Gray }


    [PSCustomObject]@{
        Timestamp = $Date
        Target    = $Target
        Status    = $Status
        Message   = $Message
    } | Export-Csv -Path $LogFile -Append -NoTypeInformation
}


Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   JAMB AUTOBOT - LAN CONTROLLER" -ForegroundColor Cyan
Write-Host "========================================="
Write-Host "1. Control CENTER 1 (192.168.x.x)"
Write-Host "2. Control CENTER 2 (172.16.x.x)"
Write-Host "Q. Quit"
$CenterChoice = Read-Host "Select Center"

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


Write-Host "-----------------------------------------"
Write-Host "1. Launch Application"
Write-Host "2. Shutdown Systems"
$ActionChoice = Read-Host "Select Action"

if ($ActionChoice -eq "1") {
    $Action = "Launch"
    $ScriptFile = "$PSScriptRoot\Remote-Launch-App.ps1"
} elseif ($ActionChoice -eq "2") {
    $Action = "Shutdown"
    $ScriptFile = "$PSScriptRoot\Remote-Shutdown.ps1"
} else {
    Write-Warning "Invalid Action."
    exit
}


if (-not $Credential) {
    Write-Host "Enter Admin Credentials (e.g. DeployAdmin)..." -ForegroundColor Yellow
    $Credential = Get-Credential
}

$AllTargets = Get-Content $TargetList | Where-Object { -not $_.StartsWith("#") -and $_.Trim() -ne "" }
$OnlineTargets = @()

Write-Host "Checking connectivity for $($AllTargets.Count) targets..." -ForegroundColor Cyan

foreach ($Target in $AllTargets) {
    if (Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        $OnlineTargets += $Target

        Write-Host "." -NoNewline -ForegroundColor Green
    } else {
        Write-Log -Target $Target -Status "WARNING" -Message "Skipped (Offline/Unreachable)"
    }
}
Write-Host "" 
Write-Host "Online Targets: $($OnlineTargets.Count) / $($AllTargets.Count)" -ForegroundColor Cyan

if ($OnlineTargets.Count -eq 0) {
    Write-Warning "No online targets found. Aborting."
    exit
}


$ScriptBlock = [ScriptBlock]::Create((Get-Content $ScriptFile -Raw))

Write-Host "Executing $Action on $($OnlineTargets.Count) systems..." -ForegroundColor Cyan

try {

    $Results = Invoke-Command -ComputerName $OnlineTargets -Credential $Credential -ScriptBlock $ScriptBlock -ThrottleLimit 50 -ErrorVariable ExecError
    

    
    if ($Results) {
        foreach ($Res in $Results) {
            Write-Log -Target $Res.PSComputerName -Status "SUCCESS" -Message "Command Executed"
        }
    }
    



    $SuccessHosts = if ($Results) { $Results.PSComputerName } else { @() }
    

    $FailedHosts = $OnlineTargets | Where-Object { $SuccessHosts -notcontains $_ }
    
    foreach ($Failed in $FailedHosts) {
        Write-Log -Target $Failed -Status "ERROR" -Message "Command Failed (Access Denied?)"
        Write-Host "Action Required: Run 'ENABLE-LAN-DEPLOY.bat' on $Failed" -ForegroundColor Yellow
    }

} catch {
    Write-Host "Batch Execution Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Done. Logs saved to $LogFile" -ForegroundColor Cyan
Pause
