$File = "$PSScriptRoot\Center1_Targets.txt"
$IPs = @()


4..255 | ForEach-Object { $IPs += "192.168.0.$_" }
1..10  | ForEach-Object { $IPs += "192.168.1.$_" }

$IPs | Out-File $File -Encoding ascii
Write-Host "Generated $($IPs.Count) targets for CENTER 1 in $File" -ForegroundColor Cyan
