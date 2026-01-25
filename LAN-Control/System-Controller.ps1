Param(
    [string]$TargetList = "$PSScriptRoot\TargetList.txt",
    [ValidateSet("Launch", "Shutdown")]
    [string]$Action,
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\Controller_Log.csv"


function Write-Log {
    Param($Target, $Status, $Message)
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = [PSCustomObject]@{
        Timestamp = $Date
        Target    = $Target
        Action    = $Action
        Status    = $Status
        Message   = $Message
    }
    $LogEntry | Export-Csv -Path $LogFile -Append -NoTypeInformation
    
    if ($Status -eq "SUCCESS") { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Green }
    elseif ($Status -eq "ERROR")   { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Red }
    else                           { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Yellow }
}


if (-not $Action) {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "   JAMB AUTOBOT - LAN CONTROLLER" -ForegroundColor Cyan
    Write-Host "========================================="
    Write-Host "1. Launch Application on All Targets"
    Write-Host "2. Shutdown All Targets"
    Write-Host "Q. Quit"
    Write-Host "========================================="
    
    $Choice = Read-Host "Select an option"
    switch ($Choice) {
        "1" { $Action = "Launch" }
        "2" { $Action = "Shutdown" }
        "Q" { exit }
        Default { Write-Warning "Invalid selection."; exit }
    }
}

if (-not $Credential) {
    Write-Host "Please enter the Admin credentials for Target PCs (e.g. DeployAdmin)..." -ForegroundColor Yellow
    $Credential = Get-Credential
}

if (-not (Test-Path $TargetList)) {
    Write-Error "Target list file not found: $TargetList"
    exit
}
$Targets = Get-Content $TargetList | Where-Object { -not $_.StartsWith("#") -and $_.Trim() -ne "" }
$Count = $Targets.Count
Write-Host "Loaded $Count targets." -ForegroundColor Cyan

$ScriptBlock = $null
if ($Action -eq "Launch") {
    $ScriptFile = "$PSScriptRoot\Remote-Launch-App.ps1"
    $ScriptBlock = [ScriptBlock]::Create((Get-Content $ScriptFile -Raw))
    Write-Host "Mode: LAUNCH APPLICATION" -ForegroundColor Green
}
elseif ($Action -eq "Shutdown") {
    $ScriptFile = "$PSScriptRoot\Remote-Shutdown.ps1"
    $ScriptBlock = [ScriptBlock]::Create((Get-Content $ScriptFile -Raw))
    Write-Host "Mode: REMOTE SHUTDOWN" -ForegroundColor Red
}

foreach ($Target in $Targets) {
    Write-Host "Processing $Target ..." -NoNewline
    
    try {
        if (-not (Test-Connection -ComputerName $Target -Count 1 -Quiet)) {
            Write-Log -Target $Target -Status "ERROR" -Message "Host Unreachable (Ping failed)"
            continue
        }

        Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock $ScriptBlock -ErrorAction Stop
        
        Write-Log -Target $Target -Status "SUCCESS" -Message "Command sent successfully."
        
    } catch {
        $ErrMsg = $_.Exception.Message
        Write-Log -Target $Target -Status "ERROR" -Message $ErrMsg
    }
}

Write-Host "========================================="
Write-Host "batch Execution Complete. Check logs at: $LogFile" -ForegroundColor Cyan
Pause
