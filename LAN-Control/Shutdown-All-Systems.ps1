Param(
    [string]$TargetList = "$PSScriptRoot\TargetList.txt",
    [PSCredential]$Credential,
    [int]$DelaySeconds = 30
)

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\Shutdown_Log.csv"

if (-not $Credential) {
    $Credential = Get-Credential
}

if (-not (Test-Path $TargetList)) {
    Write-Error "Target list not found."
    exit
}

$Targets = Get-Content $TargetList | Where-Object { $_.Trim() -ne "" }

$ScriptBlock = {
    Param([int]$Delay)
    $ErrorActionPreference = "Stop"
    
    Start-Process "shutdown.exe" -ArgumentList "/s /f /t $Delay" -Wait -NoNewWindow
    return "SHUTDOWN_INITIATED"
}

Write-Host "Initiating Parallel Shutdown on $($Targets.Count) systems..." -ForegroundColor Cyan

try {
    $Results = Invoke-Command -ComputerName $Targets -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $DelaySeconds -ThrottleLimit 50 -ErrorAction SilentlyContinue
    
    foreach ($Res in $Results) {
        [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Target    = $Res.PSComputerName
            Status    = "SHUTDOWN_INITIATED"
        } | Export-Csv -Path $LogFile -Append -NoTypeInformation
        Write-Host "Shutdown sent to $($Res.PSComputerName)" -ForegroundColor Green
    }
    
    $SuccessHosts = $Results.PSComputerName
    $FailedHosts = $Targets | Where-Object { $SuccessHosts -notcontains $_ }
    
    foreach ($Failed in $FailedHosts) {
         [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Target    = $Failed
            Status    = "FAILED"
        } | Export-Csv -Path $LogFile -Append -NoTypeInformation
        Write-Host "Failed to reach $Failed" -ForegroundColor Red
    }

} catch {
    Write-Error "Fatal error during batch shutdown: $_"
}

