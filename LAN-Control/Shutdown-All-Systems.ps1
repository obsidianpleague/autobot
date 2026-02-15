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

$ScriptBlock = {
    Param([int]$Delay)
    Start-Process "shutdown.exe" -ArgumentList "/s /f /t $Delay" -Wait -NoNewWindow
}

try {
    $Results = Invoke-Command -ComputerName $OnlineTargets -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $DelaySeconds -ThrottleLimit 50 -ErrorVariable ExecError

    $SuccessHosts = if ($Results) { $Results.PSComputerName } else { @() }
    $FailedHosts = $OnlineTargets | Where-Object { $SuccessHosts -notcontains $_ }

    foreach ($Failed in $FailedHosts) {
         Write-Log -Target $Failed -Status "ERROR" -Message "Shutdown Failed (Access Denied?)" -LogFile $LogFile
         Write-Host "   ! FAILED: $Failed - Check Admin Rights / Run ENABLE-LAN-DEPLOY.bat" -ForegroundColor Red
    }

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Shutdown command execution complete." -ForegroundColor Cyan
Pause
