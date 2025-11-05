$computers = Import-Csv -Path .\computers.csv

foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer.Displayname -ScriptBlock {
        param($UserName, $Password)
        
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -Value '1' -Force
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultUserName' -Value $UserName -Force
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'DefaultPassword' -Value $Password -Force
    } -ArgumentList $computer.UserName, $computer.Password
		
	Restart-Computer -ComputerName $computer.Displayname -force
}
