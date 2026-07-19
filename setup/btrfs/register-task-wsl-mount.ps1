$a1 = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "--mount --vhd E:\data\wsl\vhd\linux-userdata-0.vhdx --bare"
$a2 = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "--mount --vhd D:\data\wsl\vhd\linux-userdata-1.vhdx --bare"  # mirror only

$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME `
               -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName "WSL attach data disks" `
  -Action @($a1,$a2) -Trigger $trigger -Principal $principal
