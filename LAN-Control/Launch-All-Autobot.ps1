Param(
    [string]$TargetList = "$PSScriptRoot\TargetList.txt",
    [PSCredential]$Credential
)

$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\Launch_Log.csv"

if (-not $Credential) {
    $Credential = Get-Credential
}

if (-not (Test-Path $TargetList)) {
    Write-Error "Target list not found."
    exit
}

$Targets = Get-Content $TargetList | Where-Object { $_.Trim() -ne "" }

$ScriptBlock = {
    $ErrorActionPreference = "Stop"
    $AppPath_System = "C:\Program Files\autobot-jamb-browser\autobot-jamb-browser.exe"
    $AppPath_User   = "$env:LOCALAPPDATA\Programs\autobot-jamb-browser\autobot-jamb-browser.exe"
    
    $TargetExe = ""
    if (Test-Path $AppPath_System) { $TargetExe = $AppPath_System }
    elseif (Test-Path $AppPath_User) { $TargetExe = $AppPath_User }
    
    if (-not $TargetExe) { return "APP_NOT_FOUND" }

    $quser = quser 2>&1
    if ($LASTEXITCODE -ne 0) { return "NO_USER_SESSION" }
    
    $ActiveSession = $quser | Where-Object { $_ -match "Active" -or $_ -match "Console" } | Select-Object -First 1
    if (-not $ActiveSession) { return "NO_ACTIVE_USER" }
    
    $TargetUser = $ActiveSession.Trim().Split(" ")[0].Replace(">", "")
    
    $TaskName = "AutoBot_Launch"
    Start-Process -FilePath "schtasks.exe" -ArgumentList "/Create /TN $TaskName /TR `"`"$TargetExe`"`" /SC ONCE /ST 00:00 /IT /RU $TargetUser /RP `"`" /F /RL HIGHEST" -Wait -NoNewWindow
    Start-Process -FilePath "schtasks.exe" -ArgumentList "/Run /TN $TaskName" -Wait -NoNewWindow
    Start-Sleep -Seconds 3
    Start-Process -FilePath "schtasks.exe" -ArgumentList "/Delete /TN $TaskName /F" -Wait -NoNewWindow
    
    return "LAUNCHED"
}

foreach ($Target in $Targets) {
    $Status = "UNKNOWN"
    try {
        if (Test-Connection -ComputerName $Target -Count 1 -Quiet) {
            $Result = Invoke-Command -ComputerName $Target -Credential $Credential -ScriptBlock $ScriptBlock -ErrorAction Stop
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
