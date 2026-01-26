$ErrorActionPreference = "Stop"
$LogFile = "$PSScriptRoot\install_log.txt"
$IpFile = "$PSScriptRoot\next_ip.txt"

Function Log-Message {
    Param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$env:COMPUTERNAME - $Message - $TimeStamp" | Out-File -FilePath $LogFile -Append -Encoding ascii
}

Add-Type -AssemblyName Microsoft.VisualBasic

$SuggestedIP = ""
if (Test-Path $IpFile) {
    try {
        $Content = Get-Content $IpFile -Raw
        $SuggestedIP = $Content.Trim()
    } catch {
        Log-Message "Warning: Could not read next_ip.txt"
    }
}

$IP = [Microsoft.VisualBasic.Interaction]::InputBox('Verify or Enter Static IP Address:', 'IP Configuration', $SuggestedIP)

if ([string]::IsNullOrWhiteSpace($IP)) {
    Log-Message "Skipped: User cancelled or provided empty IP."
    exit
}

Log-Message "User confirmed IP: $IP"

$Adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1

if ($Adapter) {
    Try {
        Log-Message "Configuring adapter $($Adapter.Name) with IP $IP..."
        
        Remove-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        
        Set-NetIPInterface -InterfaceAlias $Adapter.Name -Dhcp Disabled -AddressFamily IPv4
        
        New-NetIPAddress -InterfaceAlias $Adapter.Name -IPAddress $IP -PrefixLength 16 -AddressFamily IPv4 -ErrorAction Stop
        
        $CurrentIPConfig = Get-NetIPAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4
        
        if ($CurrentIPConfig.IPAddress -eq $IP -and $CurrentIPConfig.PrefixLength -eq 16) {
            Log-Message "SUCCESS: IP verified as $IP with Subnet 255.255.0.0"
        } else {
            throw "IP verification failed. Found: $($CurrentIPConfig.IPAddress) with PrefixLength $($CurrentIPConfig.PrefixLength)"
        }
    }
    Catch {
        Log-Message "ERROR: Failed to set IP. $_"
        [System.Windows.Forms.MessageBox]::Show("Failed to set IP: $_", "Error", 0, 16)
        exit
    }
} else {
    Log-Message "ERROR: No active network adapter found."
    [System.Windows.Forms.MessageBox]::Show("No active network adapter found.", "Error", 0, 16)
    exit
}

Try {
    $Octets = $IP.Split('.')
    if ($Octets.Count -eq 4) {
        $Octets[3] = [int]$Octets[3] + 1
        
        if ($Octets[3] -gt 255) {
            $Octets[3] = 0
            $Octets[2] = [int]$Octets[2] + 1
        }
        
        $NextIP = "{0}.{1}.{2}.{3}" -f $Octets[0], $Octets[1], $Octets[2], $Octets[3]
        
        Set-Content -Path $IpFile -Value $NextIP
        Log-Message "Updated next_ip.txt to $NextIP"
    }
}
Catch {
    Log-Message "ERROR: Failed to increment IP in file. $_"
}

Add-Type -AssemblyName System.Windows.Forms
$WshShell = New-Object -ComObject WScript.Shell
$WshShell.Popup("IP Configured: $IP", 2, "Done", 64)
