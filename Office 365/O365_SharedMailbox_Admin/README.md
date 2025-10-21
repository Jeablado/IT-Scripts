# Scripts PowerShell - Gestion des accès aux boîtes partagées Exchange Online

Ce dossier contient trois scripts PowerShell permettant d'exporter, d'ajouter et de retirer des droits d'accès sur des boîtes partagées (BP) dans Exchange Online.

## Prérequis

- Module PowerShell ExchangeOnlineManagement installé
- Droits d'administration sur Exchange Online
- PowerShell 5.1 ou supérieur

## Fichiers

### 1_export BP agent.ps1

**Description :**  
Exporte la liste des boîtes partagées auxquelles un utilisateur donné a accès (FullAccess).  
Le résultat est enregistré dans le fichier `BP_Access.csv`.
A noter que l'on peut utiliser le joker * pour sélectionner plusieurs addresses partageant une partie de leur addresse ou alias (exemple: domaine-bp* ou *@domaine.com)

**Utilisation :**
```powershell
.\1_export BP agent.ps1 -UserEmail "utilisateur@domaine.com" -SharedMailboxIdentity "NomOuEmailDeLaBP"
```

### 2_add BP agent.ps1

**Description :**  
Ajoute les droits d'accès (FullAccess et SendAs) à l'utilisateur spécifié sur toutes les boîtes partagées listées dans `BP_Access.csv`.

**Utilisation :**
```powershell
.\2_add BP agent.ps1 -UserEmail "utilisateur@domaine.com"
```

### 3_remove BP agent.ps1

**Description :**  
Retire les droits d'accès (FullAccess et SendAs) à l'utilisateur spécifié sur toutes les boîtes partagées listées dans `BP_Access.csv`.

**Utilisation :**
```powershell
.\3_remove BP agent.ps1 -UserEmail "utilisateur@domaine.com"
```

## Notes

- Le fichier `BP_Access.csv` est généré par le script d'export et utilisé par les scripts d'ajout et de retrait de droits.
- Exécutez les scripts dans l'ordre : export, puis ajout ou retrait selon le besoin.