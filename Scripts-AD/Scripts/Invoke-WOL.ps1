param (
    [string]$MacAddress,
    [string]$ComputerName
)

$config = Import-PowerShellDataFile -Path "..\config.psd1"
$wolShutDownLog = $config.RootDirectory + $config.WolShutDownLogPath
$ArpMacAddressesWorkingDataPath = $config.RootDirectory + $config.MacFromArpWorkingDataPath

Start-Transcript -Append -Path $wolShutDownLog

$computerList = [System.Collections.Generic.List[pscustomobject]]::new()
# Import du fichier .clixml et assignation des données à la liste $computerList
try{
	Import-Clixml -Path $arpMacAddressesWorkingDataPath | ForEach-Object {
    $computerList.Add([pscustomobject]@{
        Name = $_.Name
        IP = $_.IP
        Mac = $_.Mac
    })
}

} catch {
    Write-Host "Impossible d'importer MacFromArp.clixml, appuyez sur une touche pour quitter..."
    [void][System.Console]::ReadKey($true)
    exit
}

function Send-WakeOnLan {
    param (
        [string]$MacAddress,
        [string]$ComputerName,
        [string]$Broadcast = "255.255.255.255",
        [int]$Port = 9
    )

    # Nettoyage du format de la MAC
    $macBytes = ($MacAddress -replace '[-:]', '') -split '(.{2})' | Where-Object { $_ } | ForEach-Object {[byte]('0x' + $_)}

    # Création du paquet magique : 6 x 0xFF + 16 x MAC
    $packet = [byte[]](,0xFF * 6 + ($macBytes * 16))

    # Envoi du paquet UDP en broadcast
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.Connect($Broadcast, $Port)
    $udpClient.Send($packet, $packet.Length) | Out-Null
    $udpClient.Close()
    
    Write-Host "Magic packet envoyé à $MacAddress"
}


# Si ni param Mac ni param ComputerName indiqué, envoyer à toute la liste
if (-not $MacAddress -and -not $ComputerName) {
    $computerList | Where-Object { $_.Mac } | ForEach-Object {
        Send-WakeOnLan -MacAddress $_.Mac
    }
# Si uniquement ComputerName indiqué, chercher Mac puis envoyer
} elseif (-not $MacAddress) {
        $computer = $computerList | Where-Object { $_.Name -eq $ComputerName } | Select-Object -First 1

        if ($computer) {
            if ($computer.MAC) {
                Send-WakeOnLan -MacAddress $computer.MAC
            } else {
                Write-Output "$($computer.Name) ne contient pas de MAC"
            }
        } else {
            Write-Output "Nom de périphérique incorrect ou non présent dans la base de données"
        }
# Si Mac indiqué, envoyer à Mac
} else {
    Send-WakeOnLan -MacAddress $MacAddress
}

Stop-Transcript