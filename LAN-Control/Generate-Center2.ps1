$File = "$PSScriptRoot\Center2_Targets.txt"
$IPs = @()


4..255 | ForEach-Object { $IPs += "172.16.0.$_" }
0..50  | ForEach-Object { $IPs += "172.16.1.$_" }

$IPs | Out-File $File -Encoding ascii
Write-Host "Generated $($IPs.Count) targets for CENTER 2 in $File" -ForegroundColor Cyan
