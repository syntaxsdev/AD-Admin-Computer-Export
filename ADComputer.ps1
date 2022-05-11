$ComputerNames = Get-ADComputer -Filter {OperatingSystem -like '*Windows 10*' -and Name -like '*DESKTOP-*' -and Enabled -eq 'True'} -SearchBase "dc=domain,DC=com"
$Folder = "C:\Users\USERNAME\Dev"
$CSVFile = New-Item "$Folder\AdminList.csv"
Add-Content $CSVFile "Computer Name,Admins"

$ComputerNames | % {
    $CompName = $_.Name
    $AdminUsers = $null
    try {
        $AdminUsers = gwmi Win32_groupuser -ComputerName $CompName | Where-Object {$_.GroupComponent -like "*Administrators*"} | Select-Object PartComponent
        } catch { Write-Host "[$CompName] is offline or dead."; return }

        $Admins = ""
        $NonAdmins = "Domain Admins", "Help Desk Staff", "Administrator"	

        foreach ($User in $AdminUsers.PartComponent) {
            $NameIndex = $User.IndexOf("Name=") + 6
            $SamAccountName = $User.substring($NameIndex, ($User.Length - $NameIndex) - 1)
            if ($SamAccountName -notin $NonAdmins) {
                $Admins += "$SamAccountName,"
            }
        }
        if ($Admins -ne '') {
            Write-Host "[$CompName] is active. Has $($AdminUsers.Length) admins"
            Add-Content $CSVFile "$CompName,$Admins"
        }
}