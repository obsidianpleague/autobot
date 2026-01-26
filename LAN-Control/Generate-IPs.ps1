$File = "$PSScriptRoot\TargetList.txt"
$IPs = @()

6..255 | ForEach-Object { $IPs += "192.168.0.$_" }

0..52 | ForEach-Object { $IPs += "192.168.1.$_" }

$IPs | Out-File $File -Encoding ascii
Write-Host "Generated $($IPs.Count) targets in $File"
