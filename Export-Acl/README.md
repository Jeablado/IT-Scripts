# Export ACLs des répertoires

Ce script PowerShell permet d’exporter les listes de contrôle d’accès (ACL) des dossiers listés dans un fichier CSV.  
Il supporte une option de récursivité avec contrôle du niveau de profondeur.

---

## Prérequis

- PowerShell 7 ou supérieur (pour supporter l’option `-Depth` de `Get-ChildItem`)  
- Fichier CSV nommé parentPaths.csv contenant la liste des chemins des dossiers, avec une colonne `Path`

---

## Usage

```powershell
.\Export-Acl.ps1 [-Recurse] [-MaxDepth <int>]