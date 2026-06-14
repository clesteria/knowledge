$UserHive = "C:\Users\User\NTUSER.DAT"
$MountName = "UserTemp"

red.exe load "HKU\$MountName" $UserHive

New-PSDrive -Name "HKU" -PSProvider "Registry" -Root "HKEY_USERS" -ErrorAction "SilentlyContinue"

reg.exe unload "HKU\$MountName"
