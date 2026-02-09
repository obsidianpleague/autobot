$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\reconfigure_log.txt"

Function Log-Message {
    Param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$TimeStamp - $Message"
    Write-Host $LogEntry
    $LogEntry | Out-File -FilePath $LogFile -Append -Encoding ascii
}

Function Get-ActiveEthernetAdapter {
    $Adapters = Get-NetAdapter | Where-Object {
        $_.Status -eq 'Up' -and
        $_.InterfaceDescription -notlike '*Virtual*' -and
        $_.InterfaceDescription -notlike '*Loopback*' -and
        $_.MediaType -eq '802.3'
    }
    
    if (-not $Adapters) {
        $Adapters = Get-NetAdapter | Where-Object {
            $_.Status -eq 'Up' -and
            $_.InterfaceDescription -notlike '*Virtual*' -and
            $_.InterfaceDescription -notlike '*Loopback*'
        }
    }
    
    return $Adapters | Select-Object -First 1
}

Function Get-CurrentIP {
    Param($Adapter)
    $IPConfig = Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object { $_.IPAddress -notlike '169.254.*' } |
                Select-Object -First 1
    return $IPConfig.IPAddress
}

Function Generate-MACFromIP {
    Param([string]$IP)
    
    $VendorOUIs = @(
        "00-1A-A0",
        "00-21-5A",
        "00-25-64",
        "3C-D9-2B",
        "6C-2B-59",
        "70-5A-0F",
        "98-90-96",
        "A4-1F-72",
        "B4-2E-99",
        "C8-1F-66",
        "D4-BE-D9",
        "E8-6A-64",
        "F0-1F-AF",
        "00-50-56",
        "18-66-DA",
        "34-17-EB"
    )
    
    $Salt = "-ICT-CENTER-2026"
    $InputBytes = [System.Text.Encoding]::UTF8.GetBytes($IP + $Salt)
    $HashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($InputBytes)
    $HashHex = [System.BitConverter]::ToString($HashBytes).Replace("-","")
    
    $OUIIndex = [int]("0x" + $HashHex.Substring(0,2)) % $VendorOUIs.Count
    $OUI = $VendorOUIs[$OUIIndex]
    
    $MAC = $OUI + "-" + 
           $HashHex.Substring(2,2) + "-" + 
           $HashHex.Substring(4,2) + "-" + 
           $HashHex.Substring(6,2)
    
    return $MAC
}

Function Set-MACAddress {
    Param($Adapter, [string]$NewMAC)
    
    $MACClean = $NewMAC.Replace("-","").Replace(":","")
    
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
    $Found = $false
    
    Get-ChildItem $RegPath -ErrorAction SilentlyContinue | ForEach-Object {
        $Props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($Props.DriverDesc -eq $Adapter.InterfaceDescription) {
            Set-ItemProperty -Path $_.PSPath -Name "NetworkAddress" -Value $MACClean -ErrorAction Stop
            $Found = $true
            Log-Message "MAC address set in registry for adapter: $($Adapter.InterfaceDescription)"
        }
    }
    
    if (-not $Found) {
        throw "Could not find registry key for adapter: $($Adapter.InterfaceDescription)"
    }
    
    return $true
}

Log-Message "========== MAC ADDRESS CHANGE STARTED =========="
Log-Message "Computer Name: $env:COMPUTERNAME"

$Adapter = Get-ActiveEthernetAdapter

if (-not $Adapter) {
    Log-Message "ERROR: No active Ethernet adapter found!"
    throw "No active Ethernet adapter found"
}

Log-Message "Found adapter: $($Adapter.Name) - $($Adapter.InterfaceDescription)"
Log-Message "Current MAC: $($Adapter.MacAddress)"

$CurrentIP = Get-CurrentIP -Adapter $Adapter

if (-not $CurrentIP) {
    Log-Message "ERROR: Could not determine current IP address!"
    throw "Could not determine current IP address"
}

Log-Message "Current IP: $CurrentIP"

$NewMAC = Generate-MACFromIP -IP $CurrentIP

Log-Message "New MAC will be: $NewMAC"

try {
    Log-Message "Applying MAC address..."
    Set-MACAddress -Adapter $Adapter -NewMAC $NewMAC
    Log-Message "MAC address applied successfully (will take effect after restart)"
}
catch {
    Log-Message "ERROR: MAC address change failed - $($_.Exception.Message)"
    throw $_
}

Log-Message "========== MAC CHANGE COMPLETE =========="
Log-Message "System will restart in 10 seconds..."

$WshShell = New-Object -ComObject WScript.Shell
$WshShell.Popup("MAC Address Changed!`n`nNew MAC: $NewMAC`n`nRestarting in 10 seconds...", 8, "MAC Change Complete", 64)

Start-Process "shutdown.exe" -ArgumentList "/r /t 10 /f /c `"MAC address change complete - restarting`"" -NoNewWindow -Wait
