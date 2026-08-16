$user = "$env:USERDOMAIN\$env:USERNAME"

$a1 = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "--mount --vhd E:\data\wsl\vhd\linux-userdata-0.vhdx --bare"
$a2 = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "--mount --vhd D:\data\wsl\vhd\linux-userdata-1.vhdx --bare"  # mirror only

# Unqualified -User may serialize into an empty <LogonTrigger/> that never fires;
# always pass DOMAIN\user and verify with Export-ScheduledTask after registering.
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$trigger.Delay = "PT30S"   # let WSL service / disks settle after logon

$principal = New-ScheduledTaskPrincipal -UserId $user `
               -LogonType Interactive -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Unregister-ScheduledTask -TaskName "WSL attach data disks" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "WSL attach data disks" `
  -Action @($a1,$a2) -Trigger $trigger -Principal $principal -Settings $settings
