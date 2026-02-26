Param(
    [PSCredential]$Credential,
    [int]$DelaySeconds = 0
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Targets-Config.ps1"
$LogFile = "$PSScriptRoot\Shutdown_Log.csv"

Write-Host "=========================================" -ForegroundColor Red
Write-Host "   EMERGENCY SHUTDOWN CONTROLLER" -ForegroundColor Red
Write-Host "========================================="

$TargetList = Select-Center -ActionLabel "Shutdown"
$Credential = Get-DeployCredential -Credential $Credential

$AllTargets = Get-Targets -TargetList $TargetList
$OnlineTargets = Get-OnlineTargets -AllTargets $AllTargets -LogFile $LogFile

Write-Host "SHUTTING DOWN $($OnlineTargets.Count) SYSTEMS..." -ForegroundColor Red
Start-Sleep -Seconds 2

try {
    Stop-Computer -ComputerName $OnlineTargets -Credential $Credential -Force -ErrorAction SilentlyContinue -ErrorVariable ShutdownErrors
} catch {}

foreach ($Target in $OnlineTargets) {
    $TargetFailed = $false
    foreach ($Err in $ShutdownErrors) {
        if ("$Err" -match [regex]::Escape($Target)) {
            $TargetFailed = $true
            break
        }
    }
    if ($TargetFailed) {
        Write-Log -Target $Target -Status "ERROR" -Message "Shutdown Failed (Access Denied?)" -LogFile $LogFile
        Write-Host "   ! FAILED: $Target - Check Admin Rights / Run ENABLE-LAN-DEPLOY.bat" -ForegroundColor Red
    } else {
        Write-Log -Target $Target -Status "SUCCESS" -Message "Shutdown Sent" -LogFile $LogFile
    }
}

Write-Host "Shutdown command execution complete." -ForegroundColor Cyan
Pause
