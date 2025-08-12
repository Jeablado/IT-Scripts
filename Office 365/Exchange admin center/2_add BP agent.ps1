param(
    [Parameter(Mandatory=$true)]
    [string]$UserEmail
)

# Connexion à Exchange Online
Connect-ExchangeOnline

# Chemin du fichier CSV
$file_path = Join-Path -Path $PSScriptRoot -ChildPath "BP_Access.csv"

# Vérifie si le fichier existe
if (!(Test-Path $file_path)) {
    Write-Host "Le fichier $file_path n'existe pas. Vérifiez son emplacement." -ForegroundColor Red
    exit
}

# Lecture du fichier CSV
$bp_list = Import-Csv -Path $file_path -Delimiter "," -Header "BP"

# Parcourt chaque BP dans le fichier
foreach ($entry in $bp_list) {
    $bp = $entry.BP.Trim() # Nettoie le nom de la boîte partagée

    if ($bp -ne "") {
        Write-Host "Ajout des droits sur $bp pour $UserEmail..."
        
        # Retire le droit de lecture (ReadPermission)
        Add-MailboxPermission -Identity $bp -User $UserEmail -AccessRights FullAccess -Confirm:$false

        # Retire le droit "Envoyer en tant que" (SendAs)
        Add-RecipientPermission -Identity $bp -Trustee $UserEmail -AccessRights SendAs -Confirm:$false

        Write-Host "Droits ajoutés pour $UserEmail sur $bp" -ForegroundColor Green
    }
}