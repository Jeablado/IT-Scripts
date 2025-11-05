# Service d'Aide à la Maintenance (SAM) — README

## Résumé
Ce dépôt contient un script PowerShell interactif (`Maintenance.ps1`) destiné à faciliter les opérations courantes de maintenance sur des postes Windows : montage de lecteurs réseau, connexion d'imprimantes réseau, vidage de caches (DNS, Teams, navigateurs, Java), actions pour techniciens (suppression de profils, rafraîchissement SCCM, etc.).

## Fichiers
- `Maintenance.ps1` : script principal (interface textuelle interactive).
- `Config.json` : configuration (lecteurs et imprimantes réseau, collections SCCM, etc.).

## Prérequis
- PowerShell 5 / PowerShell 7+
- Droits administratifs pour les fonctions techniques (menu technicien). Le script relance lui-même une session élevée si nécessaire.
- Accès aux ressources réseau (partages et imprimantes) depuis la machine.

## Sécurité et précautions
- Certaines opérations sont destructives :
  - La suppression des profils utilisateurs (fonction technicien) supprime définitivement les profils listés. Vérifiez la liste avant validation.
  - Les commandes qui suppriment des caches ou redémarrent des services doivent être exécutées avec prudence si des applications critiques sont en cours d'exécution.

## Configuration (`Config.json`)
Le fichier `Config.json` définit les lecteurs réseau, imprimantes et collections SCCM. Exemple minimal :

```
{
  "Drives": [
    { "Name": "B", "Root": "\\\\MonServeur\\EspaceStockage\\Espace1" },
    { "Name": "F", "Root": "\\\\MonServeur\\EspaceStockage\\Espace2" }
  ],
  "NetworkPrinters": [
    { "Name": "Imprimante 1", "Root": "\\\\MonServeur\\EspaceImprimante\\Imprimante1" },
    { "Name": "Imprimante 2", "Root": "\\\\MonServeur\\EspaceImprimante\\Imprimante2" }
  ],
  "SccmCollections":[
    { "SiteServer": "SCCM_Server.entreprise.info", "Namespace": "root\\SMS\\Mon_Site" }
  ]
}
```

- Remarques :
  - Le champ `Root` des lecteurs peut contenir des variables d'environnement comme `$ENV:USERNAME` ; le script résout ces valeurs avant le montage.
  - Mettez à jour les chemins et noms selon votre infrastructure (serveurs de fichiers, imprimantes partagées, serveur SCCM).

## Usage
1. Ouvrir une fenêtre PowerShell. Pour certaines actions (menu technicien), il faut être administrateur — le script relance automatiquement une session élevée si nécessaire.
2. Placer `Maintenance.ps1` et `Config.json` dans le même dossier.
3. Lancer le script :

```powershell
# Depuis PowerShell (non-elevé ou élevé selon le besoin)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\Maintenance.ps1"
```

ou double-cliquez sur le fichier (si .ps1 est associé) — préférer la ligne de commande pour voir les sorties.

## Fonctions

### Fonctions principales (menu utilisateur)
- Montage des lecteurs réseaux (1) : démonte puis remonte les lecteurs listés dans `Config.json`.
- Connexion des imprimantes réseau (2) : installe les imprimantes stockées dans `Config.json`.
- FlushDNS (3) : vide le cache DNS local.
- Suppression du cache Teams (4) : arrête Teams et supprime le cache (nouvelle app Teams UWP/Win32).
- Suppression de tous les caches (5) : supprime caches Java, IE/Edge anciens, Firefox, Edge, Teams.
- Réinitialisation Jabber (6) : supprime les fichiers de cache Jabber et relance l'application.

### Fonctions technicien (menu technicien — accessible quand le script est lancé en tant qu'administrateur)
- Suppression des profils non-admin (1) : supprime tous les profils locaux sauf `adm2` et `admin` (demande confirmation avant suppression).
- Actualiser client SCCM (2) : déclenche plusieurs cycles SMS_Client via WMI.
- Collections SCCM (3) : interroge le serveur SCCM défini dans `Config.json` pour lister les collections contenant cette machine.
- Débrider BITS (4) : modifie la clé de registre pour permettre un débit illimité et redémarre le service BITS.

## Comportement d'élévation
Si vous lancez le script en tant qu'utilisateur standard et sélectionnez une option nécessitant les droits administrateurs, le script relancera une nouvelle instance PowerShell en mode élevé puis affichera le menu adapté.

## Dépannage
- Le script vérifie la présence de `Config.json` au démarrage. Si absent, il affiche une erreur et quitte.
- Si un montage réseau échoue : vérifiez la connectivité réseau, le nom du partage et les droits d'accès.
- Pour les erreurs SCCM/WMI, vérifiez la connectivité au serveur SCCM et que l'utilisateur a les droits nécessaires pour interroger WMI à distance.