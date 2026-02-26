Param(
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Targets-Config.ps1"
$LogFile = "$PSScriptRoot\Controller_Log.csv"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   JAMB AUTOBOT - LAN CONTROLLER" -ForegroundColor Cyan
Write-Host "========================================="

$TargetList = Select-Center -ActionLabel "Control"

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

$Credential = Get-DeployCredential -Credential $Credential

$AllTargets = Get-Targets -TargetList $TargetList
$OnlineTargets = Get-OnlineTargets -AllTargets $AllTargets -LogFile $LogFile

Write-Host "Executing $Action on $($OnlineTargets.Count) systems..." -ForegroundColor Cyan

if ($Action -eq "Shutdown") {

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
            Write-Host "Action Required: Run 'ENABLE-LAN-DEPLOY.bat' on $Target" -ForegroundColor Yellow
        } else {
            Write-Log -Target $Target -Status "SUCCESS" -Message "Shutdown Sent" -LogFile $LogFile
        }
    }

} else {

    $ScriptBlock = [ScriptBlock]::Create((Get-Content $ScriptFile -Raw))

    try {
        $Results = Invoke-Command -ComputerName $OnlineTargets -Credential $Credential -ScriptBlock $ScriptBlock -ThrottleLimit 50 -ErrorAction SilentlyContinue -ErrorVariable ExecError

        if ($Results) {
            foreach ($Res in $Results) {
                Write-Log -Target $Res.PSComputerName -Status "SUCCESS" -Message "Command Executed" -LogFile $LogFile
            }
        }

        $SuccessHosts = if ($Results) { $Results.PSComputerName } else { @() }
        $FailedHosts = $OnlineTargets | Where-Object { $SuccessHosts -notcontains $_ }

        foreach ($Failed in $FailedHosts) {
            Write-Log -Target $Failed -Status "ERROR" -Message "Command Failed (Access Denied?)" -LogFile $LogFile
            Write-Host "Action Required: Run 'ENABLE-LAN-DEPLOY.bat' on $Failed" -ForegroundColor Yellow
        }

    } catch {
        Write-Host "Batch Execution Error: $($_.Exception.Message)" -ForegroundColor Red
    }

}

Write-Host "Done. Logs saved to $LogFile" -ForegroundColor Cyan
Pause
