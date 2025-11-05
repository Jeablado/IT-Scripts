# Gestion de l’Auto-Logon sur plusieurs postes

Ce dépôt contient deux scripts PowerShell permettant de gérer l’auto-logon (connexion automatique) sur une liste d’ordinateurs distants.  
Les scripts utilisent un fichier CSV contenant la liste des postes ainsi que les identifiants de connexion.

---

## Contenu

### 1. `Disable-AutoLogon.ps1`

- **Objectif** : Désactive la fonctionnalité d’auto-logon sur les postes listés.
- **Fonctionnement** :  
  - Modifie la clé de registre `AutoAdminLogon` pour la mettre à `0`.  
  - Redémarre chaque ordinateur pour appliquer la modification.  
  - Permet de déconnecter automatiquement les sessions sans intervention manuelle.

### 2. `Enable-AutoLogon.ps1`

- **Objectif** : Active la fonctionnalité d’auto-logon avec un utilisateur spécifique.
- **Fonctionnement** :  
  - Modifie la clé `AutoAdminLogon` à `1`.  
  - Inscrit dans le registre le nom d’utilisateur et le mot de passe fournis.  
  - Redémarre les ordinateurs pour appliquer la connexion automatique.

### 3. `computersnames.csv`

- **Contenu** : Liste des postes et des informations nécessaires à l’auto-logon.  
- **Colonnes obligatoires** :  
  - `Displayname` : nom du poste à configurer.  
  - `Username` : nom d’utilisateur pour la connexion automatique (doit inclure le domaine, ex. `MONDOMAINE\utilisateur`).  
  - `Password` : mot de passe de l’utilisateur.

---

## Exemple de fichier CSV

```csv
Displayname,Username,Password
PC01,MONDOMAINE\utilisateur1,MotDePasse1
PC02,MONDOMAINE\utilisateur2,MotDePasse2