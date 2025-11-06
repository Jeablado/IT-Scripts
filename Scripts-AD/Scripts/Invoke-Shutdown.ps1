param (
    [string]$ComputerName,
    [switch]$All
)

$config = Import-PowerShellDataFile -Path "..\config.psd1"
$wolShutDownLog = $config.RootDirectory + $config.WolShutDownLogPath
$ADExportWorkingDataPath = $config.RootDirectory + $config.ADExportWorkingDataPath

$importedData = Import-Clixml -Path $ADExportWorkingDataPath

Start-Transcript -Append -Path $wolShutDownLog

function Send-Shutdown {
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    # Commande de shutdown
    Stop-Computer -ComputerName $ComputerName -Force
    
    Write-Output "Shutdown: $ComputerName"
}


if ($All) {
    Write-Host "Etes vous vraiment sur de vouloir Shutdown tout le parc ? Y/n"
    $confInput = Read-Host
    if ($confInput -eq "Y"){
        $importedData | ForEach-Object {
            Send-Shutdown -ComputerName $_.Name
        }
    } 
} elseif ($ComputerName) {
    Send-Shutdown -ComputerName $ComputerName
} else {
    while ($true) {
        Write-Host "Indiquez le nom du PC à éteindre / A (All) / Q (Quit)"
        $computerNameInput = Read-Host
        if ($computerNameInput -eq "A"){
            Write-Host "Etes vous vraiment sur de vouloir Shutdown tout le parc ? O/n"
            $confInput = Read-Host
            if ($confInput -eq "O"){
                $importedData | ForEach-Object {
                    Send-Shutdown -ComputerName $_.Name
                }
            }
        } elseif ($computerNameInput -eq "Q"){
            break
        } else {
            Send-Shutdown -ComputerName $computerNameInput
        }    
    }
}