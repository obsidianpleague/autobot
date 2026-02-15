$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Targets-Config.ps1"
$LogFile = "$PSScriptRoot\MassReconfigure_Log.csv"

$RemoteScript = @'
$ErrorActionPreference = "Stop"

Function Generate-MACFromIP {
    Param([string]$IP)
    $VendorOUIs = @("00-1A-A0","00-21-5A","00-25-64","3C-D9-2B","6C-2B-59","70-5A-0F","98-90-96","A4-1F-72","B4-2E-99","C8-1F-66","D4-BE-D9","E8-6A-64","F0-1F-AF","00-50-56","18-66-DA","34-17-EB")
    $Salt = "-ICT-CENTER-2026"
    $InputBytes = [System.Text.Encoding]::UTF8.GetBytes($IP + $Salt)
    $HashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($InputBytes)
    $HashHex = [System.BitConverter]::ToString($HashBytes).Replace("-","")
    $OUIIndex = [int]("0x" + $HashHex.Substring(0,2)) % $VendorOUIs.Count
    $OUI = $VendorOUIs[$OUIIndex]
    return $OUI + "-" + $HashHex.Substring(2,2) + "-" + $HashHex.Substring(4,2) + "-" + $HashHex.Substring(6,2)
}

$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' } | Select-Object -First 1
if (-not $Adapter) { throw "No adapter" }

$IPConfig = Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1
$CurrentIP = $IPConfig.IPAddress
if (-not $CurrentIP) { throw "No IP" }

$NewMAC = Generate-MACFromIP -IP $CurrentIP

$MACClean = $NewMAC.Replace("-","")
$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
Get-ChildItem $RegPath -ErrorAction SilentlyContinue | ForEach-Object {
    $Props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if ($Props.DriverDesc -eq $Adapter.InterfaceDescription) {
        Set-ItemProperty -Path $_.PSPath -Name "NetworkAddress" -Value $MACClean -ErrorAction SilentlyContinue
    }
}

[PSCustomObject]@{
    IP = $CurrentIP
    ComputerName = $env:COMPUTERNAME
    NewMAC = $NewMAC
    Status = "SUCCESS"
}

Start-Process "shutdown.exe" -ArgumentList "/r /t 15 /f" -NoNewWindow
'@

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   MASS MAC ADDRESS CHANGE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will change MAC addresses on all targets"
Write-Host "and RESTART them immediately."
Write-Host "(Computer names will NOT be changed)"
Write-Host ""

$TargetList = Select-Center -ActionLabel "Change MACs for"

Write-Host ""
$Credential = Get-DeployCredential

$AllTargets = Get-Targets -TargetList $TargetList
$OnlineTargets = Get-OnlineTargets -AllTargets $AllTargets -LogFile $LogFile

Write-Host ""
Write-Host "WARNING: This will change MAC on $($OnlineTargets.Count) systems and restart them!" -ForegroundColor Red
$Confirm = Read-Host "Type 'YES' to proceed"
if ($Confirm -ne "YES") {
    Write-Host "Aborted."
    exit
}

$BatchSize = 50
$BatchDelay = 30
$Batches = [System.Collections.ArrayList]@()

for ($i = 0; $i -lt $OnlineTargets.Count; $i += $BatchSize) {
    $Batch = $OnlineTargets[$i..([Math]::Min($i + $BatchSize - 1, $OnlineTargets.Count - 1))]
    [void]$Batches.Add($Batch)
}

Write-Host "Executing in $($Batches.Count) batches of ~$BatchSize systems..." -ForegroundColor Cyan
$ScriptBlock = [ScriptBlock]::Create($RemoteScript)

$BatchNum = 0
foreach ($Batch in $Batches) {
    $BatchNum++
    Write-Host ""
    Write-Host "=== Batch $BatchNum / $($Batches.Count) ($($Batch.Count) systems) ===" -ForegroundColor Yellow
    
    try {
        $Results = Invoke-Command -ComputerName $Batch -Credential $Credential -ScriptBlock $ScriptBlock -ThrottleLimit 50 -ErrorAction SilentlyContinue
        
        foreach ($Res in $Results) {
            Write-Log -Target $Res.IP -Status $Res.Status -Message "$($Res.ComputerName) -> MAC: $($Res.NewMAC)" -LogFile $LogFile
        }
        
        $SuccessIPs = if ($Results) { $Results.IP } else { @() }
        $FailedTargets = $Batch | Where-Object { $SuccessIPs -notcontains $_ }
        
        foreach ($Failed in $FailedTargets) {
            Write-Log -Target $Failed -Status "ERROR" -Message "Command failed (check WinRM/credentials)" -LogFile $LogFile
        }
    }
    catch {
        Write-Host "Batch error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    if ($BatchNum -lt $Batches.Count) {
        Write-Host "Waiting $BatchDelay seconds before next batch..." -ForegroundColor Gray
        Start-Sleep -Seconds $BatchDelay
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Execution complete. Check $LogFile for details." -ForegroundColor Green
Write-Host "Allow 5-10 minutes for all systems to restart." -ForegroundColor Yellow
Pause
