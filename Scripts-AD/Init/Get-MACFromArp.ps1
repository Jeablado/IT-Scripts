$config = Import-PowerShellDataFile -Path "..\config.psd1"

$pingWorkingDataPath = $config.RootDirectory + $config.PingWorkingDataPath

$ArpMacAddressesWorkingDataPath = $config.RootDirectory + $config.MacFromArpWorkingDataPath
$ArpMacAddressesLogPath = $config.RootDirectory + $config.MacFromArpLogPath


# Début de Transcription
Start-Transcript -Append -Path $ArpMacAddressesLogPath

# Création d'une liste qui contiendra les données récupérés du Ping
# Si le fichier Ping.clixml existe, récupération des données du fichier, transformation en liste d'objets .net et ajout à la liste
$IPList = [System.Collections.Generic.List[pscustomobject]]::new()
if ((Test-Path $pingWorkingDataPath) -and (Get-Item $pingWorkingDataPath).Length -gt 0) {
    $importedIPList = Import-Clixml -Path $pingWorkingDataPath
    foreach ($element in $importedIPList) {
        $IPList.Add([pscustomobject]@{
            Name = $element.Name
            IP   = $element.IP
        })
    }
}

# Création d'une liste qui contiendra les données récupérés lors de la précédente exécution du présent script
# Si le fichier MacFromArp.clixml existe, récupération des données du fichier, transformation en liste d'objets .net et ajout à la liste
$MacList = [System.Collections.Generic.List[pscustomobject]]::new()
if ((Test-Path $ArpMacAddressesWorkingDataPath) -and (Get-Item $ArpMacAddressesWorkingDataPath).Length -gt 0) {
    $importedMacList = Import-Clixml -Path $ArpMacAddressesWorkingDataPath
    foreach ($element in $importedMacList) {
        $MacList.Add([pscustomobject]@{
            Name = $element.Name
            IP   = $element.IP
            Mac = $element.Mac
            LastMacDate = $element.LastMacDate
        })
    }
}

# Récupération de la table arp
$arpTable = get-netneighbor | Where-Object { 
	($_.IPaddress.ToString() -like ($config.networkAddress + "*")) -and
	($_.State -eq "Reachable" -or $_.State -eq "Stale")
 }

$macEntryModified = New-Object 'System.Collections.Generic.List[Object]'
$macEntryAdded = New-Object 'System.Collections.Generic.List[Object]'
$macEntryRemoved = New-Object 'System.Collections.Generic.List[Object]'

# Parcourir tous les éléments présent dans table ARP et récupérer l'IP, le nom de device dans liste IPList et la mac
$arpTable | ForEach-Object {
    $ip = $_.IPAddress.ToString()
    $name = ($IPList | Where-Object { $_.IP -eq $ip }).Name
    $mac = $_.LinkLayerAddress
    # Si nom de device existe déjà dans MacList, mettre à jour
    $entry = $MacList | Where-Object { $_.Name -eq $name }
    if ($entry) {
        $entry.IP = $ip
        $entry.Mac = $mac
        $entry.LastMacDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        $macEntryModified.Add($entry)
    # Sinon ajouter un nouvel objet
    } else {
        if (-not($null -eq $name)){
            $newEntry = [pscustomobject]@{
                Name         = $name
                IP           = $ip
                Mac          = $mac
                LastMacDate  = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
            }
            $MacList.Add($newEntry)
            $macEntryAdded.Add($newEntry)
        }
    }
}

# Si un device n'existe plus dans IPList, le supprimer de MacList (IPList retire les devices qui ne sont plus dans l'AD)
$toRemove = @()
foreach ($macEntry in $MacList) {
    $existsInIPList = $IPList | Where-Object { $_.Name -eq $macEntry.Name }
    if (-not $existsInIPList) {
        $toRemove += $macEntry
        $macEntryRemoved.Add($macEntry)
    }
}
foreach ($item in $toRemove) {
    $MacList.Remove($item)
}



if (($count = $macEntryAdded.Count) -gt 0) {
    Write-Host "Ajouts : $count"
    $macEntryAdded | ForEach-Object {"$($_.Name), $($_.IP), $($_.Mac), $($_.LastMacDate)"}
}

if (($count = $macEntryModified.Count) -gt 0) {
    Write-Host "Modification : $count"
    $macEntryModified | ForEach-Object {"$($_.Name), $($_.IP), $($_.Mac), $($_.LastMacDate)"}
}

if (($count = $macEntryRemoved.Count) -gt 0) {
    Write-Host "Suppression : $count"
    $macEntryRemoved | ForEach-Object {"$($_.Name), $($_.IP), $($_.Mac), $($_.LastMacDate)"}
}

# Export Clixml
$MacList | Export-Clixml -Path $ArpMacAddressesWorkingDataPath

Stop-Transcript