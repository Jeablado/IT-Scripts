$config = Import-PowerShellDataFile -Path "..\config.psd1"

$pingWorkingDataPath = $config.RootDirectory + $config.PingWorkingDataPath
$screensWorkingDataPath = $config.RootDirectory + $config.ScreensWorkingDataPath
$screensCsvPath = $config.RootDirectory + $config.ScreensCsvPath
$getComputersScreensLog = $config.RootDirectory + $config.GetComputersScreensLogPath

# Date du jour pour garder une trace de la date de mise à jour des écrans
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Start-Transcript -Append -Path $getComputersScreensLog
write-output $pingWorkingDataPath
$screensList = [System.Collections.Generic.List[pscustomobject]]::new()
# Si le chemin est défini dans config et qu'un fichier existe, on importe la liste des écrans
if (Test-Path $screensWorkingDataPath) {
    try {
        $importedScreenList = Import-Clixml -Path $screensWorkingDataPath
        # D'abord reconstruire une vrai liste d'object powershell depuis l'import CLIXML (imports d'objets désérialisés)
        $importedScreenList | ForEach-Object {
            $screensList.Add([PSCustomObject]@{
                Name = $_.Name
                Entity = $_.Entity
                Statut = $_.Statut
                Type = $_.Type
                Manufacturer = $_.Manufacturer
                UserFriendlyName = $_.UserFriendlyName
                UserName = $_.UserName
                Site = $_.Site
                InventaryNumber = $_.InventaryNumber
                SerialNumber = $_.SerialNumber
                ComputerName = $_.ComputerName
                IP = $_.IP
                Date = $_.Date
            })
        }
    } catch {
        Write-Output "Erreur lors de la lecture du fichier CLIXML : $_"
    }
}
############
# Import du fichier .clixml contenant résultat du ping
try {
    $importedCacheList = Import-Clixml -Path $pingWorkingDataPath
} catch {
    Write-Host "Impossible d'importer Ping.clixml, appuyez sur une touche pour quitter..."
    [void][System.Console]::ReadKey($true)
    exit
}

# Liste pour stocker tous les résultats moniteurs
$allMonitors = $importedCacheList | ForEach-Object -Parallel {
    $deviceName = $_.Name
    $deviceIP = $_.IP

    try {
        $monitors = Invoke-Command -ComputerName $deviceIP -ScriptBlock {
            Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID | ForEach-Object {
                [PSCustomObject]@{
                    Manufacturer = ([System.Text.Encoding]::ASCII.GetString($_.ManufacturerName)).Trim([char]0)
                    ProductCode  = ([System.Text.Encoding]::ASCII.GetString($_.ProductCodeID)).Trim([char]0)
                    SerialNumber = ([System.Text.Encoding]::ASCII.GetString($_.SerialNumberID)).Trim([char]0)
                    UserFriendlyName = ([System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName)).Trim([char]0)
                    UserName = (Get-CimInstance Win32_ComputerSystem).UserName
                } | Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
            }
        }

        foreach ($monitor in $monitors) {
            $monitor | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $deviceName
            $monitor | Add-Member -NotePropertyName "IP" -NotePropertyValue $deviceIP
        }

        return $monitors
    } catch {
        Write-Warning "Erreur lors de l'accès à $($deviceName) : $_"
        return $null
    }
}

$allMonitors = $allMonitors | Sort-Object SerialNumber, ComputerName -Unique

# Numéro de série d'écran déjà existant dans la liste
$existingSerials = $screensList | ForEach-Object { $_.SerialNumber }


foreach ($monitor in $allMonitors) {
    # Si n'existe pas encore
    if (($null -ne $monitor) -and ($monitor.SerialNumber -notin $existingSerials)) {
        # Recréation d'objets pour éviter les informations par défaut ajouté par PWSH à l'objet créé avec get-ciminstance
        $screensList.Add([PSCustomObject]@{
            Name = $null
            Entity = "Entité racine > Branche Famille > Région Rhône Alpes Auvergne > CAF Cantal > Informatique"
            Statut = $null
            Type = $null
            Manufacturer = $monitor.Manufacturer
            UserFriendlyName = $monitor.UserFriendlyName
            UserName = $monitor.UserName
            Site = $monitor.Site
            InventaryNumber = $null
            SerialNumber = $monitor.SerialNumber
            ComputerName = $monitor.ComputerName
            IP = $monitor.IP
            Date = $date
        })
        Write-Output "$($monitor.SerialNumber) ajouté pour $($monitor.ComputerName)"
    }
    # Suppression et Recréation de l'objet dans la liste si le numéro de série existait déjà pour le même ordinateur pour garder les informations les plus à jour
    elseif (($null -ne $monitor) -and ($monitor.SerialNumber -in $existingSerials)) {
        $screenToRemove = $screensList | Where-Object {$_.SerialNumber -eq $monitor.SerialNumber -and $_.ComputerName -ne $monitor.ComputerName }
        if ($screenToRemove){
            foreach ($item in $screenToRemove) {
                [void]$screensList.Remove($item)
                Write-Output "Suppression de l'ancien écran $($item.SerialNumber) pour $($item.ComputerName)"
            }
            $screensList.Add([PSCustomObject]@{
                Name = $monitor.Name
                Entity = $monitor.Entity
                Statut = $monitor.Statut
                Type = $monitor.Type
                Manufacturer = $monitor.Manufacturer
                UserFriendlyName = $monitor.UserFriendlyName
                UserName = $monitor.UserName
                Site = $monitor.Site
                InventaryNumber = $monitor.InventaryNumber
                SerialNumber = $monitor.SerialNumber
                ComputerName = $monitor.ComputerName
                IP = $monitor.IP
                Date = $date
            })
            Write-Output "$($monitor.SerialNumber) mis à jour pour $($monitor.ComputerName)"
        }   
    }
}

$screensList | Export-Clixml -Path $screensWorkingDataPath

# Export CSV
$screensList| Export-Csv -Path $screensCsvPath -NoTypeInformation -Encoding UTF8