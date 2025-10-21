# O365_DiffusionList_Admin

Scripts PowerShell pour synchroniser et vider des listes de diffusion Office 365 depuis Active Directory.

## Contenu
- `Add-DLMembersFromAD.ps1` — ajoute les utilisateurs AD (selon `Config.json`) aux DL Office 365.
- `Clear-DistributionList.ps1` — supprime tous les membres des DL listées dans `Config.json`.
- `Config.json` — configuration (mappage attributs → DLs, filtre AD, DLs à vider).
- `Identifiants\user.txt` et `Identifiants\TENANTNAME.key` — identifiants (non versionnés).
- Dossier `log` avec `add_log.txt`, `clear_log.txt` et `error_O365_log.txt`.

## Prérequis
- PowerShell (pwsh.exe ou Windows PowerShell compatible).
- Modules : `ExchangeOnlineManagement`, `ActiveDirectory` (RSAT).
- Compte avec droits Exchange et lecture AD.

## Emplacement des identifiants
Les scripts lisent :
- `..\..\Identifiants\user.txt` (UPN)
- `..\..\Identifiants\TENANTNAME.key` (SecureString via `ConvertFrom-SecureString`)

Attention : le fichier `.key` dépend de DPAPI (lié à l'utilisateur/machine qui l'a créé).

## Config (résumé)

Le fichier `Config.json` pilote la sélection des utilisateurs et les DL cibles. Structure attendue :

- Racine
  - `UsersAttributesAndDLs` (array) : liste de règles. Chaque règle contient :
    - `ADAttributes` (object)
      - `AttributeType` (string) : nom exact de l'attribut AD à tester (ex. `"l"`, `"department"`).
      - `AttributeData` (array[string]) : valeurs AD qui déclenchent l'ajout (ex. `["Siege","Siège"]`).
    - `TargetDLs` (array[string]) : adresses SMTP des listes de diffusion à mettre à jour.
  - `ADSettings` (object)
    - `filter` (object) : exactement un couple clé:valeur (le script extrait la clé et la valeur pour construire le filtre AD). Exemple : `{"Company":"MyCompany"}` devient `Company -eq 'MyCompany'` (le script ajoute `-and DisplayName -notlike '*automate*'`).
    - `Property` (array[string]) : propriétés à récupérer via `Get-ADUser`. Doit inclure :
      - `EmailAddress` (nécessaire pour ajouter un membre à une DL)
      - tout nom présent dans `AttributeType` (pour que la valeur soit disponible)
  - `DLsToClear` (array[string]) : adresses SMTP des listes que `Clear-DistributionList.ps1` doit vider.

## Exécution
Ouvrir PowerShell dans le dossier des scripts puis :
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Ajouter depuis AD vers DL
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Add-DLMembersFromAD.ps1

# Vider les DL listées
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Clear-DistributionList.ps1
```
Ou exécuter directement `.\Add-DLMembersFromAD.ps1` / `.\Clear-DistributionList.ps1`.

## Dépannage rapide
- Erreurs de connexion Exchange → vérifier `Identifiants` et tester `Connect-ExchangeOnline` en mode interactif.
- Pas de résultats AD → vérifier `ADSettings.filter` et que `ADSettings.Property` contient `EmailAddress`.
- Vérifier les logs dans `log\` et `error_O365_log.txt`.