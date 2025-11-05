# Scheduled Tasks Exporter

Ce script PowerShell permet d'extraire la liste des tâches planifiées sur un ou plusieurs serveurs Windows, avec possibilité d'explorer récursivement tous les dossiers des tâches.

---

## Fonctionnalités

- Connexion à un ou plusieurs serveurs Windows via CIM ou COM API.
- Exploration récursive ou simple des dossiers de tâches planifiées.
- Extraction détaillée des propriétés principales de chaque tâche (nom, chemin, auteur, description, état, déclencheurs, actions, dernières exécutions, etc.).
- Export des résultats dans un fichier CSV.

---

## Usage

### Paramètres

- **-Servers** : Liste des serveurs ciblés (par défaut, importe la liste depuis un fichier `serverList.csv`).
- **-Recurse** : Switch pour activer l'exploration récursive des dossiers de tâches.
- **-TaskPath** : Chemin du dossier des tâches à explorer (par défaut, `\` la racine).

---

### Exemple de lancement

```powershell
.\ExportScheduledTasks.ps1 -Servers "Serveur1","Serveur2" -Recurse -TaskPath "\"