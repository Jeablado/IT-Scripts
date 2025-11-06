$config = Import-PowerShellDataFile -Path "..\config.psd1"

$pingWorkingDataPath = $config.RootDirectory + $config.PingWorkingDataPath
$loggedOnUsersCsvPath = $config.RootDirectory + $config.loggedOnUsersCsvPath
$ADExportWorkingDataPath = $config.RootDirectory + $config.ADExportWorkingDataPath
$pingLogPath = $config.RootDirectory + $config.PingLogPath

# Début de Transcription
Start-Transcript -Append -Path $pingLogPath

# Vidange du cache dns pour s'assurer que le Ping se fera avec des informations vierges
Clear-DnsClientCache


# Création d'une liste qui contiendra les données récupérés du Ping
# Si le fichier Ping.clixml existe, récupération des données du fichier, transformation en liste d'objets .net et ajout à la liste
$deviceList = [System.Collections.Generic.List[pscustomobject]]::new()
if ((Test-Path $pingWorkingDataPath) -and (Get-Item $pingWorkingDataPath).Length -gt 0) {
    $importedList = Import-Clixml -Path $pingWorkingDataPath
    foreach ($element in $importedList) {
        $deviceList.Add([pscustomobject]@{
            Name = $element.Name
            IP   = $element.IP
            LastPingSuccessTime = $element.LastPingSuccessTime
            LastLoggedOnUser = $element.LastLoggedOnUser
            LastLoggedOnUserDate = $element.LastLoggedOnUserDate
        })
    }
}

# Imports des données AD
$ADExport = Import-Clixml -Path $ADExportWorkingDataPath

# Ping de chaque machine et récupération de l'adresse IP
$results = $ADExport | ForEach-Object -Parallel {
    $ping = Test-Connection -ComputerName $_.Name -Count 1 -ErrorAction SilentlyContinue

    # Ajout des données IP et Status
    if ($ping.Status -eq "Success") {
        $IP = $ping.Address.IPAddressToString
        $LastPingSuccessTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss" 
    } else {
        $IP = $null
        $LastPingSuccessTime = $null
    }

    [PSCustomObject]@{
        Name = $_.Name
        IP = $IP
        LastPingSuccessTime = $LastPingSuccessTime
        LastLoggedOnUser = $null
        LastLoggedOnUserDate = $null
    }
}

$successfulPingNewItem = New-Object 'System.Collections.Generic.List[Object]'
$successfulPingUpdatedIP = New-Object 'System.Collections.Generic.List[Object]'
$successfulPingNothingToChange = New-Object 'System.Collections.Generic.List[Object]'
$unsuccessfulPing = New-Object 'System.Collections.Generic.List[Object]'


foreach ($item in $results) {
    if ($null -ne $item.IP) {
        $user = Invoke-Command -ComputerName $item.Name -ScriptBlock { query user }
        if ($user.Count -gt 1 -and $user[1] -match "^ (\w+)") {
            $item.LastLoggedOnUser = $matches[1]
            $item.LastLoggedOnUserDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        }
    }

    $existing = $deviceList | Where-Object { $_.Name -eq $item.Name } | Select-Object -First 1
    # Si l'objet n'existe pas encore dans deviceList et que le ping a réussi, l'ajouter
    if ((-not $existing) -and ($null -ne $item.LastPingSuccessTime)){
        $deviceList.Add($item)
        $successfulPingNewItem.Add("$($item.Name), $($item.IP), $($existing.LastLoggedOnUser)")
    }
    # Si l'objet existe déjà dans deviceList et que le ping a réussi...
    elseif (($existing) -and ($null -ne $item.LastPingSuccessTime)) {
        # ... si l'IP est différente mettre à jour IP
        if ($existing.IP -ne $item.IP) {
            $existing.IP = $item.IP
            $existing.LastPingSuccessTime = $item.LastPingSuccessTime
            if ($null -ne $item.LastLoggedOnUser){
                $existing.LastLoggedOnUser = $item.LastLoggedOnUser
                $existing.LastLoggedOnUserDate = $item.LastLoggedOnUserDate
            }
            $successfulPingUpdatedIP.Add("$($existing.Name), $($existing.IP), $($existing.LastLoggedOnUser)")
        }
        else {
            if ($null -ne $item.LastLoggedOnUser){
                $existing.LastLoggedOnUser = $item.LastLoggedOnUser
                $existing.LastLoggedOnUserDate = $item.LastLoggedOnUserDate
            }
            $existing.LastPingSuccessTime = $item.LastPingSuccessTime
            $successfulPingNothingToChange.Add("$($existing.Name), $($existing.IP), $($existing.LastLoggedOnUser)")
        }
    # Si le ping a échoué 
    } else { 
        if ($existing) {
            $existing.IP = $null
            $unsuccessfulPing.Add("$($existing.Name), Echec")
        } else {
            $unsuccessfulPing.Add("$($item.Name), Echec")
        }
    }
}

# Supprime de la liste des appareils les postes qui ne se trouvent plus dans l'AD
$computerNames = $ADExport.Name

#Clone de la liste originale pour itérer dessus lorsque je modifie l'originale
# Clone simple en tableau pour éviter l'erreur
$deviceListClone = @($deviceList)

$removedItem = New-Object 'System.Collections.Generic.List[Object]'

foreach ($device in $deviceListClone) {
    if ($device.Name -notin $computerNames) {
        $removedItem.Add("$($device.Name), $($device.IP)")
        $deviceList.Remove($device)
    }
}

Write-Host "----------PING OK----------"
if (($count = $successfulPingNewItem.Count) -gt 0){
    Write-Host "Objet nouvellement ajouté au fichier Ping: $count"
    $successfulPingNewItem | ForEach-Object {$_}
}
if (($count = $successfulPingUpdatedIP.Count) -gt 0){
    Write-Host "IP mise à jour dans fichier Ping: $count"
    $successfulPingUpdatedIP | ForEach-Object {$_}
}
if (($count = $successfulPingNothingToChange.Count) -gt 0){
    Write-Host "Aucune modification de l'IP dans fichier Ping: $count"
    $successfulPingNothingToChange | ForEach-Object {$_}
}

if (($count = $unsuccessfulPing.Count) -gt 0){
    Write-Host "----------PING NOK---------"
    Write-Host "Ping en échec: $count"
    $unsuccessfulPing | ForEach-Object {$_}
}

if (($count = $removedItem.Count) -gt 0){
    Write-Host "--------SUPPRESSION--------"
    Write-Host "Eléments supprimés: $count"
    $removedItem | ForEach-Object {$_}
}

$deviceList | Export-Clixml -Path $pingWorkingDataPath

New-Item -ItemType Directory -Path (Split-Path $LoggedOnUsersCsvPath) -Force -ErrorAction SilentlyContinue | Out-Null

$deviceList | Export-Csv -Path $LoggedOnUsersCsvPath -NoTypeInformation -Encoding UTF8

Stop-Transcript