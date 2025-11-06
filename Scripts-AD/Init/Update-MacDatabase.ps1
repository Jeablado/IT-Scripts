$config = Import-PowerShellDataFile -Path "..\config.psd1"

$TestAllComputers = Join-Path $config.RootDirectory "\Init\Test-AllComputers.ps1"
$GetArpMacAddresses = Join-Path $config.RootDirectory "\Init\Get-MACFromArp.ps1"

& $TestAllComputers
& $GetArpMacAddresses