$ErrorActionPreference = "Stop"
$IpFile = "$PSScriptRoot\next_ip.txt"


Function Log-Write {
    Param([string]$Msg)
    Write-Host $Msg -ForegroundColor Cyan
}

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms


$SuggestedIP = ""
if (Test-Path $IpFile) {
    try {
        $Content = Get-Content $IpFile -Raw
        $SuggestedIP = $Content.Trim()
    } catch {
        Log-Write "Could not read next_ip.txt"
    }
}
if (-not $SuggestedIP) { $SuggestedIP = "192.168.0.1" }


$IP = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the Static IP Address for this machine:", "IP Configuration", $SuggestedIP)

if ([string]::IsNullOrWhiteSpace($IP)) {
    Write-Host "Operation Cancelled." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    exit
}


Log-Write "Detecting Ethernet Adapter..."
$Adapter = Get-NetAdapter | Where-Object {
    $_.Status -eq 'Up' -and
    $_.MediaType -eq '802.3' -and
    $_.InterfaceDescription -notmatch 'Virtual|Loopback|VMware|VirtualBox|Wi-Fi|Wireless'
} | Select-Object -First 1

if (-not $Adapter) {
    $Adapter = Get-NetAdapter | Where-Object {
        $_.Status -eq 'Up' -and
        $_.InterfaceDescription -notmatch 'Wi-Fi|Wireless|Virtual|Loopback'
    } | Select-Object -First 1
}

if ($Adapter) {
    try {
        Log-Write "Configuring Adapter: $($Adapter.Name)"
        Log-Write "Setting IP: $IP"
        Log-Write "Subnet: 255.255.0.0"


        Remove-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        

        Set-NetIPInterface -InterfaceAlias $Adapter.Name -Dhcp Disabled -AddressFamily IPv4


        New-NetIPAddress -InterfaceAlias $Adapter.Name -IPAddress $IP -PrefixLength 16 -AddressFamily IPv4 -ErrorAction Stop

        Log-Write "SUCCESS! IP Set to $IP"
        

        try {
            $Octets = $IP.Split('.')
            if ($Octets.Count -eq 4) {
                $LastOctet = [int]$Octets[3]
                $LastOctet++
                

                if ($LastOctet -le 254) {
                    $NextIP = "{0}.{1}.{2}.{3}" -f $Octets[0], $Octets[1], $Octets[2], $LastOctet
                    Set-Content -Path $IpFile -Value $NextIP
                    Log-Write "Next IP will be: $NextIP"
                }
            }
        } catch {
            Log-Write "Warning: Could not increment next IP"
        }


        $WshShell = New-Object -ComObject WScript.Shell
        $WshShell.Popup("IP Configured Successfully!`nIP: $IP`nMask: 255.255.0.0", 2, "Success", 64)

    } catch {
        Log-Write "ERROR: $_"
        [System.Windows.Forms.MessageBox]::Show("Error setting IP: $_", "Error", 0, 16)
        Pause
    }
} else {
    Log-Write "ERROR: No active network adapter found!"
    [System.Windows.Forms.MessageBox]::Show("No active network adapter found.`nPlease check cable connection.", "Error", 0, 16)
    Pause
}
