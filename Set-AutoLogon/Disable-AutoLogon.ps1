$computers = Import-Csv -Path .\computers.csv

Foreach($computer in $computers) 
{ 
	$computer.Displayname
	Invoke-Command -ComputerName $computer.Displayname -ScriptBlock { Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoAdminLogon' -Value '0' -force }

	Restart-Computer -ComputerName $computer.Displayname -force
}