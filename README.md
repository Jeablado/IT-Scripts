# Scripts PowerShell – IT Admin Toolkit

Ce dépôt contient une collection de scripts PowerShell utilisés au quotidien dans des tâches de support technique, d’administration système et d’automatisation.

## Contenu
- **Exportateur ACL** : récupère les droits ACL sur différents dossiers définis
- **Planificateur de tâches** : outils pour lister et analyser les tâches planifiées sur un ou plusieurs serveurs.
- **Microsoft 365** : scripts pour la gestion des boîtes aux lettres partagées et des listes de diffusions.
- **AutoLogon Setter** : active / désactive l'autologon sur des machines données

## Utilisation
1. **Cloner le dépôt** ou télécharger le script souhaité :
   `git clone https://github.com/Jeablado/IT-Scripts.git`
2. **Ouvrir PowerShell en tant qu’administrateur.**
3. **Autoriser temporairement l’exécution des scripts** (pour cette session uniquement) :
   `Set-ExecutionPolicy -Scope Process Bypass`
4. **Lancer le script** :
   `.\NomDuScript.ps1 -Parametre1 Valeur1 -Parametre2 Valeur2`

## Remarques importantes
- Les scripts sont fournis tels quels et doivent être testés sur un environnement de préproduction avant déploiement en production.
- L’ExecutionPolicy en Bypass n’est appliquée qu’à la session PowerShell courante, elle ne modifie pas la configuration globale du poste.
- Certains scripts peuvent nécessiter des modules PowerShell supplémentaires (ExchangeOnlineManagement, ActiveDirectory, etc.).

## Licence
Ce projet est distribué sous licence MIT – vous êtes libre de réutiliser et modifier ces scripts.