Les tâches planifiées sont enregistrées en local pour faciliter le run.
Mais une copie est enregistrée sous: 
S:\20 Informatique\6 - Back_up_taches_planifiees_win11
Penser à mettre à jour le back-up lorsque l'on modifie les fichiers enregistrés dans le dossier courant



----- IMPORTANT --------

Les informations de connexions des différents scripts se trouvent dans les fichiers "user.txt" et TENANTNAME.key".
Ce sont ces deux fichiers qui doivent être modifiés en cas de changement d'utilisateur ou de mot de passe.
user.txt: écrire uniquement l'adresse e-mail de l'utilisateur
TENANTNAME.key: mot de passe cripté de l'utilisateur, à générer en faisant tourner le fichier MDPKey.ps1 (à exécuter depuis la session powershell de l'utilisateur, pas la session ADM2, mais bien la session utilisateur)

------------------------