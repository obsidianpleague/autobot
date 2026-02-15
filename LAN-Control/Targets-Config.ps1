$Script:CenterConfig = @{
    "1" = @{ Name = "CENTER 1"; Subnet = "192.168.x.x"; File = "$PSScriptRoot\Center1_Targets.txt" }
    "2" = @{ Name = "CENTER 2"; Subnet = "172.16.x.x";  File = "$PSScriptRoot\Center2_Targets.txt" }
}

$Script:DeployAdminUser = "DeployAdmin"

function Write-Log {
    Param(
        [string]$Target,
        [string]$Status,
        [string]$Message,
        [string]$LogFile
    )
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($Status -eq "SUCCESS")     { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Green }
    elseif ($Status -eq "ERROR")   { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Red }
    elseif ($Status -eq "WARNING") { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Yellow }
    else                           { Write-Host "[$Date] $Target : $Status - $Message" -ForegroundColor Gray }

    if ($LogFile) {
        [PSCustomObject]@{
            Timestamp = $Date
            Target    = $Target
            Status    = $Status
            Message   = $Message
        } | Export-Csv -Path $LogFile -Append -NoTypeInformation
    }
}

function Select-Center {
    Param([string]$ActionLabel = "Control")

    foreach ($Key in ($Script:CenterConfig.Keys | Sort-Object)) {
        $C = $Script:CenterConfig[$Key]
        Write-Host "$Key. $ActionLabel $($C.Name) ($($C.Subnet))"
    }
    Write-Host "Q. Cancel"
    $Choice = Read-Host "Select Center"

    if ($Choice -eq "Q") { exit }

    if (-not $Script:CenterConfig.ContainsKey($Choice)) {
        Write-Warning "Invalid selection."
        exit
    }

    $Selected = $Script:CenterConfig[$Choice]
    if (-not (Test-Path $Selected.File)) {
        Write-Error "Target list not found ($($Selected.File)). Run GENERATE-TARGETS.bat first."
        exit
    }

    return $Selected.File
}

function Get-Targets {
    Param([string]$TargetList)
    return Get-Content $TargetList | Where-Object { -not $_.StartsWith("#") -and $_.Trim() -ne "" }
}

function Get-OnlineTargets {
    Param([string[]]$AllTargets, [string]$LogFile)

    $Online = @()
    Write-Host "Scanning $($AllTargets.Count) targets..." -ForegroundColor Cyan
    foreach ($Target in $AllTargets) {
        if (Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $Online += $Target
            Write-Host "." -NoNewline -ForegroundColor Green
        } else {
            if ($LogFile) {
                Write-Log -Target $Target -Status "WARNING" -Message "Skipped (Offline/Unreachable)" -LogFile $LogFile
            }
        }
    }
    Write-Host ""
    Write-Host "Online: $($Online.Count) / $($AllTargets.Count)" -ForegroundColor Cyan

    if ($Online.Count -eq 0) {
        Write-Warning "No targets online."
        exit
    }

    return $Online
}

function Get-DeployCredential {
    Param([PSCredential]$Credential)

    if (-not $Credential) {
        Write-Host "Enter $Script:DeployAdminUser Credentials..." -ForegroundColor Yellow
        $Credential = Get-Credential -Message "Enter $Script:DeployAdminUser password"
    }
    return $Credential
}
