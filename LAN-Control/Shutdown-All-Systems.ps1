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

foreach ($Target in $Targets) {
    $Status = "UNKNOWN"
    try {
        if (Test-Connection -ComputerName $Target -Count 1 -Quiet) {
            $Result = Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $DelaySeconds -ErrorAction Stop
            $Status = $Result
        } else {
            $Status = "UNREACHABLE"
        }
    } catch {
        $Status = "ERROR"
    }
    
    [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Target    = $Target
        Status    = $Status
    } | Export-Csv -Path $LogFile -Append -NoTypeInformation
}
