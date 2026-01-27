SOLO SCRIPTS - IP CONFIGURATION TOOL

How to Use:
1. Double-click "Set-IP.bat".
2. Accept the "Admin" prompt.
3. A popup will ask for the IP address.
   - It suggests the IP from "next_ip.txt".
4. Click OK.
   - The script sets the IP on your active Ethernet adapter.
   - It sets the Subnet Mask to 255.255.0.0.
   - It validates the setting.
5. If successful, it updates "next_ip.txt" for the next machine (e.g., .1 -> .2).

Files:
- Set-IP.bat: The launcher.
- Set-IP-Interactive.ps1: The script logic.
- next_ip.txt: Stores the next IP to use. Edit this if you want to jump to a specific range.
