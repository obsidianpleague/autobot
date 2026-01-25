$File = "$PSScriptRoot\TargetList.txt"
$IPs = @()

0..255 | ForEach-Object { $IPs += "172.16.0.$_" }
0..50 | ForEach-Object { $IPs += "172.16.1.$_" }

$IPs | Out-File $File -Append -Encoding ascii
