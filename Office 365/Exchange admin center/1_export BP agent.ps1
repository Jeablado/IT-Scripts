param(
    [Parameter(Mandatory=$true)]
    [string]$UserEmail,

    [Parameter(Mandatory=$true)]
    [string]$SharedMailboxIdentity
)

Connect-ExchangeOnline

$boitesPartagees = Get-Mailbox -ResultSize Unlimited -Identity $SharedMailboxIdentity | Where-Object { ($_.RecipientTypeDetails -eq "SharedMailbox") }

$accessList = @()


# Parcourt chaque boîte partagée
foreach ($boitePartagee in $boitesPartagees) {
    # Obtient la liste des membres de la boîte partagée
    $membres = Get-MailboxPermission -ResultSize Unlimited -Identity $boitePartagee.Identity |
               Where-Object { $_.AccessRights -like "*FullAccess*" } |
               Select-Object -ExpandProperty User

    # Vérifie si l'utilisateur spécifié est membre de la boîte partagée
    if ($membres -contains $UserEmail) {
        Write-Output "$($boitePartagee.DisplayName)"
        $accessList += "$($boitePartagee.DisplayName),"
    }
}

$file_path = Join-Path $PSScriptRoot "BP_Access.csv"
if (Test-Path $file_path) { Remove-Item $file_path -Force }
$accessList | Set-Content -Path $file_path