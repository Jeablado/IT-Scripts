# Scripts-AD

## Description

**Scripts-AD** est un ensemble de scripts PowerShell conçus pour administrer et auditer un environnement Active Directory.  
Ils permettent notamment d'extraire des informations sur les utilisateurs, les machines, les écrans, et de gérer le Wake-on-LAN et l'arrêt à distance.

  **PowerShell 7+ requis**

---

## Arborescence du projet

Scripts-AD/
├── Init/ # Scripts d'initialisation et de collecte (AD, ping, ARP, etc.)
├── Scripts/ # Scripts de travail se basant sur la collecte de Init
├── WorkingData/ # Données brutes issues des scripts Init
├── Logs/ # Fichiers journaux générés par chaque script
├── OutputCSV/ # Fichiers CSV exportés (utilisateurs connectés, écrans)
├── config.psd1 # Fichier de configuration globale
└── README.md # Documentation principale

---

## Prérequis

- PowerShell **7.0 ou supérieur**
- Droits d'administration sur le réseau/local
- Accès réseau aux postes à auditer
- Lancer depuis une machine jointe au domaine

---

## Contenu des dossiers

### Init/
Contient les scripts suivants :
- `Export-ADComputers.ps1` — Exporte les objets ordinateurs de l’Active Directory. Les serveurs présents dans l’AD doivent être **exclus via le fichier `config.psd1`** pour éviter de les inclure dans les traitements réseau.
- `Update-MacDatabase.ps1` — Lance le script Test-AllComputers.ps1 puis Get-MACFromARP.ps1 pour mettre à jour la base de donnée des adresses MAC
- `Test-AllComputers.ps1` — Ping de toutes les machines du parc et extrait les utilisateurs connectés
- `Get-MACFromARP.ps1` — Récupération des adresses MAC via ARP


### Scripts/
- `Get-ComputersScreens.ps1` — Récupère les écrans (modèles, utilisateur, ip etc.) connectés aux machines du parc
- `Invoke-WOL.ps1` — Wake-on-LAN d'une machine ou du parc complet
- `Invoke-Shutdown.ps1` — Arrêt distant d'une machine ou du parc complet

### WorkingData/
- Contient les fichiers bruts générés par les scripts (ARP, ping, AD, etc.)

### Logs/
- Un fichier de log par script exécuté (timestamp, erreurs, machines non accessibles…)

### OutputCSV/
- `LoggedOnUsers.csv` — Liste des utilisateurs connectés
- `ComputersScreens.csv` — Inventaire des écrans

---

## Configuration

Les paramètres globaux (ex : plages IP, chemins, groupes AD ciblés) sont définis dans `config.psd1`.

---

## Exemple d'utilisation

Ce projet contient plusieurs scripts PowerShell organisés par usage. Voici un scénario d'utilisation typique, avec les bonnes pratiques de planification.

### 1. Exécuter les scripts initiaux (`Init/`)

Ces scripts permettent de collecter des données réseau et Active Directory. Ils sont pensés pour être **automatisés via le Planificateur de tâches Windows** (`taskschd.msc`).

```powershell
.\Init\Export-ADComputers.ps1     # Inventaire AD des postes (à lancer 1x par jour)
.\Init\Update-MacDatabase.ps1     # Lance Test-Allcomputers.ps1 et Get-MacFromArp.ps1 (3x par jour recommandé)
.\Init\Test-AllComputers.ps1      # Scan réseau par ping avec récupération des utilisateurs connectés. Pensez à exclure les serveurs dans le fichier `config.psd1` pour éviter de les inclure dans le scan réseau.
.\Init\Get-MACFromARP.ps1         # Association IP / Nom de poste ↔ adresse MAC via la table ARP
```

### 2. Récupérer les écrans
.\Scripts\Get-ComputerScreens.ps1

### 3. Wake-on-LAN
.\Scripts\Invoke-WOL.ps1 [-ComputerName] [-MacAddress]

- Si un nom de poste (`-ComputerName`) ou une adresse Mac (`-MacAddress`) est indiqué en argument, le script envoie le paquet Wake-on-LAN uniquement à cet ordinateur.  
- Si aucun paramètre n’est fourni, le script envoie le paquet Wake-on-LAN à tout le parc.  


### 4. Shutdown
.\Scripts\Invoke-Shutdown.ps1 [-ComputerName] [-All]

- Si un nom de poste (`-ComputerName`) est indiqué en argument, le script éteint uniquement cet ordinateur.  
- Si le paramètre `-All` est présent, le script envoie un shutdown à tout le parc.  
- Si aucun paramètre n’est fourni, le script demande via `Read-Host` si l’on souhaite éteindre un ordinateur spécifique ou tout le parc.

---

## Notes

- Les scripts doivent être exécutés depuis un compte disposant des droits nécessaires pour interroger le réseau et l'Active Directory.
- Le projet est **principalement en lecture seule** et ne modifie pas les machines, sauf pour les scripts Wake-on-LAN et Shutdown qui agissent directement sur les machines ciblées.
- Pensez à lancer les scripts dans une session PowerShell 7 ou supérieure pour garantir la compatibilité.