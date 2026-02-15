Param(
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Targets-Config.ps1"
$LogFile = "$PSScriptRoot\Launch_Log.csv"

Write-Host "=========================================" -ForegroundColor Green
Write-Host "   MASS LAUNCH CONTROLLER" -ForegroundColor Green
Write-Host "========================================="

$TargetList = Select-Center -ActionLabel "Launch on"
$Credential = Get-DeployCredential -Credential $Credential

$AllTargets = Get-Targets -TargetList $TargetList
$OnlineTargets = Get-OnlineTargets -AllTargets $AllTargets -LogFile $LogFile

Write-Host "Launching App on $($OnlineTargets.Count) systems..." -ForegroundColor Green
$ScriptBlock = [ScriptBlock]::Create((Get-Content "$PSScriptRoot\Remote-Launch-App.ps1" -Raw))

try {
    $Results = Invoke-Command -ComputerName $OnlineTargets -Credential $Credential -ScriptBlock $ScriptBlock -ThrottleLimit 50

    $SuccessHosts = if ($Results) { $Results.PSComputerName } else { @() }
    $FailedHosts = $OnlineTargets | Where-Object { $SuccessHosts -notcontains $_ }

    foreach ($Failed in $FailedHosts) {
         Write-Log -Target $Failed -Status "ERROR" -Message "Launch Failed (Access Denied?)" -LogFile $LogFile
         Write-Host "   ! FAILED: $Failed - Check Admin Rights / Run ENABLE-LAN-DEPLOY.bat" -ForegroundColor Red
    }

    if ($Results) {
        foreach ($Res in $Results) { Write-Log -Target $Res.PSComputerName -Status "SUCCESS" -Message "Launch Sent" -LogFile $LogFile }
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Execution complete." -ForegroundColor Cyan
Pause
