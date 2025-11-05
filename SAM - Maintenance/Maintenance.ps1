#Region GlobalVariables
$ComputerName = $env:COMPUTERNAME
$UserName = $env:USERNAME
$EMail = (dsregcmd /status | Select-String "Executing Account Name").Line.Split()[-1]
$configPath = Join-Path $PSScriptRoot "config.json"
    if (!(Test-Path $configPath)) {
        Write-Host "Erreur : le fichier config.json est introuvable à l'emplacement $configPath" -ForegroundColor Red
        return
    }
$config = Get-Content $configPath -Raw | ConvertFrom-Json
#EndRegion

#Region UserFunctions
function Mount-NetworkDrive {
    Clear-Host
    Write-Host "Démontage des espaces de stockage en cours ... `n"
    Start-Sleep -Milliseconds 200

    $drives = $config.Drives

    foreach ($drive in $drives) {
        try {
        Remove-SmbMapping -LocalPath "$($drive.Name):" -Force -ErrorAction Stop
        Write-Host "Démontage du lecteur effectué : $($drive.Name)"
        } catch {
        Write-Host "Démontage du lecteur $($drive.Name) impossible : $($_.Exception.Message)"
        }
    }
    
    Start-Sleep -Seconds 1

    Write-Host "Montage des espaces de stockage en cours ... `n"
    foreach ($drive in $drives) {
        $drivePath = Invoke-Expression "`"$($drive.Root)`"" #Permet de résoudre les chemins contenant des variables d'environnement
        net use "$($drive.Name):" "$drivePath" *>$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Montage du lecteur $($drive.Name) effectué"
        } else {
            Write-Warning "Montage du lecteur $($drive.Name) impossible"
        }
    }

    Start-Sleep -Seconds 3

    Write-Host "`nMontage des espaces de stockage effectué"
    pause
}

function Connect-NetworkPrinters {
    Clear-Host
    Write-Host "Connexion en cours ...`n"
    $printers = $config.NetworkPrinters
    foreach ($printer in $printers) {
        try {
            Add-Printer -ConnectionName $printer.Root -ErrorAction Stop
            Write-Host "$($printer.Name) connectée`n"
        }
        catch {
            Write-Host "Erreur lors de la connexion à $($printer.Name) : $($_.Exception.Message)"
        }
    }
    Pause
}

function Clear-Dns {
    Clear-Host
    try {
        Clear-DnsClientCache
        Write-Host "Cache DNS vidé`n"
    } catch {
        Write-Host "Erreur lors du vidage du cache DNS : $($_.Exception.Message)`n"
    }
    Pause
}

function Clear-TeamsCache {
    Clear-Host
    Write-Host "Suppression du cache Teams en cours`n"
    try {
        Stop-Process -Name "ms-teams" -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
    } catch {
        Write-Host "Erreur lors de la fermeture de Teams : Le processus ms-teams n'est pas en cours d'execution ou n'a pas été trouvé avec ce nom`n"
    }

    $TeamsCachePath = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams"
    if (Test-Path $TeamsCachePath) {
        Remove-Item -Path $TeamsCachePath -Recurse -Force -ErrorAction Stop
        Write-Host "Cache Teams vidé`n"
    } else {
        Write-Host "Le cache Teams n'existe pas ou a déjà été supprimé.`n"
    }
    Pause
}

function Clear-AllCaches {
    Clear-Host

    # Fermer les processus
    $processes = @("javaw", "iexplore", "MsEdge", "firefox", "ms-teams")
    Write-Host "Fermeture des processus`n"
    foreach ($proc in $processes) {
        try {
            Stop-Process -Name $proc -Force -ErrorAction Stop
            Write-Host "$proc fermé avec succès"
        } catch {
            Write-Host -ForegroundColor Red "Erreur lors de la fermeture de $proc : Le processus '$proc' n'est pas en cours d'execution ou n'a pas été trouvé avec ce nom"
        }
    }

    Start-Sleep -Milliseconds 3000
    
    Write-Host "`n`nSuppression des caches`n"

    # Supprimer le cache Java
    try {
        javaws -clearcache
        $JavaCache = "$env:USERPROFILE\AppData\LocalLow\Sun\Java\Deployment\cache\6.0"
        if (Test-Path $JavaCache) {
            Remove-Item -Path $JavaCache -Recurse -Force -ErrorAction Stop
            Write-Host "Cache Java supprimé"
        } else {
            Write-Host -ForegroundColor Red "Le cache Java n'existe pas ou a déjà été supprimé"
        }
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de la suppression du cache Java : $($_.Exception.Message)"
    }

    # Supprimer le cache Internet Explorer / Edge ancien
    RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red "Erreur lors de la suppression des caches IE, code de sortie : $LASTEXITCODE"
    } else {
        Write-Host "Cache Internet Explorer supprimés"
    }

    # Supprimer les caches et historiques Firefox
    try {
        $FirefoxProfiles = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $FirefoxProfiles) {
            Get-ChildItem -Path $FirefoxProfiles | Remove-Item -Recurse -Force -ErrorAction Stop
            Write-Host "Cache Firefox supprimés"
        } else {
            Write-Host -ForegroundColor Red "Le cache Firefox n'existe pas ou a déjà été supprimé"
        }
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de la suppression des caches Firefox : $($_.Exception.Message)"
    }

    # Supprimer caches Edge actuel
    try {
        $EdgeCache1 = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage"
        $EdgeCache2 = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data"
        if (Test-Path $EdgeCache1) { 
            Remove-Item -Path $EdgeCache1 -Recurse -Force -ErrorAction Stop
            Write-Host "Cache Microsoft Edge 1 supprimés"
        }
        else {Write-Host -ForegroundColor Red "Le cache Edge $EdgeCache1 n'existe pas ou a déjà été supprimé"}
        if (Test-Path $EdgeCache2) { 
            Remove-Item -Path $EdgeCache2 -Recurse -Force -ErrorAction Stop
            Write-Host "Cache Microsoft Edge 2 supprimés"
        }
        else {Write-Host -ForegroundColor Red "Le cache Edge $EdgeCache2 n'existe pas ou a déjà été supprimé"}
        
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de la suppression des caches Edge : $($_.Exception.Message)"
    }


    # Supprimer cache Teams New
    try {
        $TeamsCache = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams"
        if (Test-Path $TeamsCache) {
            Remove-Item -Path $TeamsCache -Recurse -Force -ErrorAction Stop
            Write-Host "Cache Teams supprimé"
        } else {
            Write-Host -ForegroundColor Red "Le cache Teams $TeamsCache n'existe pas ou a déjà été supprimé"
        }
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de la suppression du cache Teams : $($_.Exception.Message)"
    }

    Pause
}

function Clear-JabberCache {
    Clear-Host
    try {
        Stop-Process -Name CiscoJabber -Force -ErrorAction Stop
    } catch {
        Write-Host "Erreur lors de la fermeture de Cisco Jabber : Le processus CiscoJabber n'est pas en cours d'execution ou n'a pas été trouvé avec ce nom"
    }
    $JabberCache = "$env:USERPROFILE\AppData\Roaming\Cisco\Unified Communications\Jabber"
    try {
        Remove-Item -Path $JabberCache -Recurse -Force
        Write-Host "Cache Cisco Jabber supprimé avec succès`n"
        Write-Host -ForegroundColor Green "Informations de connexion"
        Write-Host "Nom d'utilisateur: $UserName"
        Write-Host "Mot de passe: Le long mot de passe Windows, pas le pin"
    } catch {
        Write-Host "Erreur lors de la suppression de $JabberCache : $($_.Exception.Message)"
    }
    Start-Sleep -Milliseconds 1000
    try {
        Start-Process -FilePath "C:\Program Files (x86)\Cisco Systems\Cisco Jabber\CiscoJabber.exe"
    } catch {
        Write-Host "Impossible de lancer Cisco Jabber : $($_.Exception.Message)"
    }
    Write-Host "`n"
    Pause
}

function Start-TechnicianMenu{
    If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        #$PSCommandPath donne le chemin absolu du script powershell actuel
        $scriptPath = $PSCommandPath
        Start-Process powershell.exe -ArgumentList "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
    else{
        Show-TechnicianMenu
    }
}


#Endregion

#Region SUDO
function Remove-NonAdminUserProfiles {
    Clear-Host

    $profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath -like "C:\Users\*" -and $_.Special -eq $false }
    $profilesToDelete = $profiles | Where-Object { (Split-Path $_.LocalPath -Leaf) -notmatch '^(adm2|admin)' }
    
    Write-Host "Profils à supprimer :"
    $profilesToDelete | ForEach-Object {
        Write-Host (Split-Path $_.LocalPath -Leaf)
    }

    $reponse = Read-Host "Voulez-vous supprimer les profils ci-dessus ? (O/N)"

    switch ($reponse.ToUpper()) {
        "O" {$profilesToDelete | ForEach-Object {
                $username = Split-Path $_.LocalPath -Leaf
                try {
                    Remove-CimInstance -InputObject $_ -Confirm:$false
                    Write-Host "Profil supprimé : $username"
                } catch {
                    Write-Warning "Impossible de supprimer le profil $username : $_"
                } 
            } 
        }
        "N" { Show-TechnicianMenu}
        }

    Write-Host "Profils restants sur le poste: "
    $profiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath -like "C:\Users\*"}
    $profiles | ForEach-Object {
        Write-Host (Split-Path $_.LocalPath -Leaf)
    }
    Read-Host "Appuyez Entrée pour retourner au menu des techniciens"
    Show-TechnicianMenu
}

function Invoke-SCCMClientRefresh {
    Clear-Host

    $triggers = @(
    "{00000000-0000-0000-0000-000000000001}", # Cycle inventaire matériel
    "{00000000-0000-0000-0000-000000000002}", # Cycle inventaire logiciel
    "{00000000-0000-0000-0000-000000000003}", # Cycle collecte des données d'inscription
    "{00000000-0000-0000-0000-000000000010}", # Cycle de mesure des logiciels (Software Metering)
    "{00000000-0000-0000-0000-000000000021}", # Cycle politique machine
    "{00000000-0000-0000-0000-000000000022}", # Cycle politique utilisateur
    "{00000000-0000-0000-0000-000000000032}", # Mise à jour de la liste des sources Windows Installer
    "{00000000-0000-0000-0000-000000000071}", # Cycle d'évaluation de conformité
    "{00000000-0000-0000-0000-000000000108}", # Cycle des mises à jour logicielles
    "{00000000-0000-0000-0000-000000000121}"  # Cycle d'évaluation des applications
    )

    Write-Host "`n---- Début du rafraîchissement SCCM sur ce poste ----"

    foreach ($Cycle in $triggers) {
        try {
            Invoke-WmiMethod -Namespace "root\ccm" -Class SMS_Client -Name TriggerSchedule -ArgumentList $Cycle -ErrorAction Stop
            Write-Host "Cycle $Cycle déclenché avec succès."
        } catch {
            Write-Warning "Erreur lors du déclenchement du cycle $Cycle : $_"
        }
    }
    Read-Host "`n---- Rafraîchissement SCCM terminé ----`nAppuyez Entrée pour retourner au menu des techniciens "
    Show-TechnicianMenu
}

function Get-SCCMCollections{
    Clear-Host
    $SccmCollections = $config.SccmCollections
    foreach($SccmCollection in $SccmCollections) {
        $SiteServer = $SccmCollection.Siteserver
        $Namespace = $SccmCollection.Namespace
        $Collections = Get-WmiObject -ComputerName $SiteServer -Namespace $Namespace -Query "SELECT * FROM SMS_FullCollectionMembership WHERE ResourceID IN (SELECT ResourceID FROM SMS_R_System WHERE Name = '$ComputerName')"
        Write-Output "PC: $ComputerName`n"
        foreach ($Collection in $Collections) {
            $collectionName = Get-WmiObject -ComputerName $SiteServer -Namespace $Namespace -Query "SELECT Name FROM SMS_Collection WHERE CollectionID = '$($Collection.CollectionID)'"
            write-Output $collectionName.Name
        }
    }
    Read-Host "`nAppuyez Entrée pour retourner au menu des techniciens"
    Show-TechnicianMenu

}

function Enable-BitsUnlimitedMode {
    Clear-Host
    Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\BITS" -name "EnableBitsMaxBandwidth" -Value 0 -type DWord
    try {
        Restart-Service -Name bits -Force -ErrorAction Stop
        Write-Host "Service BITS redémarré." -ForegroundColor Green
    } catch {
        Write-Warning "Impossible de redémarrer le service BITS. Redémarrez manuellement si nécessaire."
    }
    Read-Host "Appuyez Entrée pour retourner au menu des techniciens"
    Show-TechnicianMenu
}

#Endregion

#Region EasterEggs

function Show-TheAnswerToLifeTheUniverseAndEverything {
    Clear-Host
    Write-Host "Calcul en cours de :`nLa grande question sur la vie, l'Univers et le reste`n" -ForegroundColor Magenta
    Start-Sleep -Seconds 3
    Write-Host "Temps de calcul estimé: 7.5 millions années`n" -ForegroundColor Cyan

    $duration = 10             
    $endTime = (Get-Date).AddSeconds($duration)
    $spinner = @("/","-","\", "|")   
    $i = 0

    while ((Get-Date) -lt $endTime) {
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)
        $char = $spinner[$i % $spinner.Count]
        Write-Host "$char Calcul en cours..." -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 200
        $i++
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)
        Write-Host (" " * [System.Console]::WindowWidth) -NoNewline
    }

    Write-Host "`nLe sens de la vie est :"
    for ($i = 0; $i -lt 23; $i++){
        Write-Host "." -NoNewLine
        Start-Sleep -Milliseconds 200
    }
    [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)
    Write-Host (" " * [System.Console]::WindowWidth) -NoNewline
    Write-Host "`nDe Gauche à Droite, de Haut en Bas  " -BackgroundColor Darkred
    Start-Sleep -Seconds 4
    for ($i = 0; $i -lt 8; $i++){
        Write-Host "Erreur 42                           " -BackgroundColor Darkred
        Start-Sleep -Milliseconds 300
        Write-Host "+++++++++                           " -BackgroundColor Darkred
        Start-Sleep -Milliseconds 300
    }
    Write-Host "Erreur Critique                     " -BackgroundColor Darkred
    Start-Sleep -Seconds 2
    Write-Host "                                    " -BackgroundColor Darkred
    Write-Host "Surchauffe du calculateur...        `nRetour au menu principal            " -BackgroundColor Darkred
    Start-Sleep -Seconds 5
    Show-MainMenu
}

function Show-Matrix {
    Clear-Host
    # Taille de la console
    $Width = [console]::WindowWidth
    $Height = [console]::WindowHeight

    # Tableau pour suivre la position verticale de chaque colonne
    $columns = @()
    for ($i = 0; $i -lt $Width; $i++) {
        $columns += Get-Random -Minimum -$Height -Maximum 0
    }

    # Durée totale de l'animation (en secondes)
    $duration = 4
    $endTime = (Get-Date).AddSeconds($duration)

    while ((Get-Date) -lt $endTime) {

        Clear-Host

        for ($x = 0; $x -lt $Width; $x++) {
            $y = $columns[$x]

            if ($y -ge 0 -and $y -lt $Height) {
                $char = [char](Get-Random -Minimum 33 -Maximum 126)
                [console]::SetCursorPosition($x, $y)
                Write-Host $char -ForegroundColor Green -NoNewline
            }

            # Faire tomber la lettre
            $columns[$x] = $y + 1
            if ($columns[$x] -ge $Height) {
                $columns[$x] = Get-Random -Minimum -$Height -Maximum 0
            }
        }

        Start-Sleep -Milliseconds 50
    }



    Clear-Host

    $asciiArt = @"
                     __        __   _                          _          _   _             
                     \ \      / /__| | ___ ___  _ __ __  ___  | |_ ___   | |_| |__   ___    
                      \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \/ _ \ | __/ _ \  | __| '_ \ / _ \   
                       \ V  V /  __/ | (_| (_) | | | | |  __/ | || (_) | | |_| | | |  __/   
                        \_/\_/ \___|_|\___\___/|_| |_|_|\___|  \__\___/   \__|_| |_|\___|   

                                     __  __       _        _
                                    |  \/  | __ _| |_ _ __(_)__  __
                                    | |\/| |/ _` | __/ '__|| |\ \/ /
                                    | |  | | (_| | | | |  | | >  <
                                    |_|  |_|\__,_|\_\|_|  |_|/_/\_\


    
"@ -split "`n"

        # Affichage ligne par ligne avec effet
    foreach ($line in $asciiArt) {
        Write-Host $line -ForegroundColor Green
        Start-Sleep -Milliseconds 100
    }

    Write-Host "                                            ... Loading ...`n" -ForegroundColor Green
    Write-Host "                     " -NoNewline
    for ($i = 1; $i -le 68; $i++) {
        Write-Host "█" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 50
    }
    Start-Sleep -Milliseconds 500
    Show-MainMenu -MatrixColor
}
#Endregion

#Region GraphicalUI

function Show-MainMenu{
    param(
        [switch]$MatrixColor
    )

    if ($MatrixColor){
        $Color1 = "Green"
        $Color2 = "Green"
        $Color3 = "Green"
    } else {
        $Color1 = "Blue"
        $Color2 = "White"
        $Color3 = "Red"
    }

    Clear-Host
    Write-Host ""
    Write-Host -ForegroundColor $Color1 -NoNewline "                                       *"
    Write-Host -ForegroundColor $Color2 -NoNewline "*"
    Write-Host -ForegroundColor $Color3 -NoNewline "*  "
    Write-Host -ForegroundColor $Color2 -NoNewLine "Service d'Aide à la Maintenance"
    Write-Host -ForegroundColor $Color1 -NoNewline "  *"
    Write-Host -ForegroundColor $Color2 -NoNewline "*"
    Write-Host -ForegroundColor $Color3 "*`n`n"

    Write-Host -ForegroundColor $Color1 -NoNewline "    ********************************************"
    Write-Host -ForegroundColor $Color3 "                      ***********************"
    Write-Host -ForegroundColor $Color1 -NoNewline "    **** "
    Write-Host -ForegroundColor $Color2 -NoNewline "Sélectionnez l'action à effectuer"
    Write-Host -ForegroundColor $Color1 -NoNewline "  ****"
    Write-Host -ForegroundColor $Color3 -NoNewline "                      ** "
    Write-Host -ForegroundColor $Color2 -NoNewline "Infos utilisateur"
    Write-Host -ForegroundColor $Color3 " **"
    Write-Host -ForegroundColor $Color1 -NoNewline "    ********************************************"
    Write-Host -ForegroundColor $Color3 "                      ***********************`n"
    Write-Host -NoNewline "    1. Montage des lecteurs réseaux"
    Write-Host -NoNewline "                                |  "
    Write-Host "Nom du poste:"
    Write-Host -NoNewline "                                                                   |  "
    Write-Host -ForegroundColor $Color3 "$ComputerName"
    Write-Host -NoNewline "    2. Connecter les imprimantes réseaux"
    Write-Host -NoNewline "                           |  "
    Write-Host "Nom utilisateur:"
    Write-Host -NoNewline "                                                                   |  "
    Write-Host -ForegroundColor $Color3 "$UserName"
    Write-Host -NoNewline "    3. FlushDNS"
    Write-Host -NoNewline "                                                    |  "
    Write-Host "E-mail utilisateur:"
    Write-Host -NoNewline "                                                                   |  "
    Write-Host -ForegroundColor $Color3 "$EMail"
    Write-Host -NoNewline "    4. Suppression des caches Teams"
    Write-Host "                                 --------------------------------- `n"
    Write-Host "    5. Suppression tous caches (Java, IE, Edge, Firefox, Teams) `n"
    Write-Host "    6. Réinitialisation jabber `n"
    $UserChoice = Read-Host "    Choix"

    switch($UserChoice) {
        # Fonctions utilisateur
        1 { Mount-NetworkDrive }
        2 { Connect-NetworkPrinters }
        3 { Clear-Dns }
        4 { Clear-TeamsCache }
        5 { Clear-AllCaches }
        6 { Clear-JabberCache }

        # Fonction technicien
        15 { Start-TechnicianMenu }

        #EasterEggs
        42 { Show-TheAnswerToLifeTheUniverseAndEverything }
        101 { Show-Matrix }
        0 { Exit }
        Default { Write-Host "`n    Option invalide.`n    Appuyez sur Entrée pour réessayer" -ForegroundColor Red; Read-Host; Show-MainMenu }
    }

}

function Show-TechnicianMenu {
    Clear-Host
    Write-Host "                            ==========================================" -ForegroundColor Darkred
    Write-Host "                                       MENU DES TECHNICIENS           " -ForegroundColor Darkred
    Write-Host "                            ==========================================" -ForegroundColor Darkred
    Write-Host ""

    $menuItems = @(
        "                            1. Suppression tous profils du poste (exceptés adm2 et admin défaut)"
        "                            2. Actualiser client SCCM"
        "                            3. Collections SCCM dans lesquelles la machine est présente"
        "                            4. Débrider réseau bits (téléchargement màj + centre logiciel télétravail)"
        "                            0. Retour au menu utilisateur"
    )

    foreach ($item in $menuItems) {
        Write-Host $item -ForegroundColor White
    }

    Write-Host ""
    $choice = Read-Host "                            Entrez votre choix (0-4)"

    switch ($choice) {
        1 { Remove-NonAdminUserProfiles }
        2 { Invoke-SCCMClientRefresh }
        3 { Get-SCCMCollections }
        4 { Enable-BitsUnlimitedMode }
        0 { Show-MainMenu }
        Default { Write-Host "`nOption invalide. Réessayez." -ForegroundColor Red; Pause; Show-TechnicianMenu }
    }
}
#Endregion

#Region StartApp

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Show-MainMenu
} else {
    Show-TechnicianMenu
}
#Endregion