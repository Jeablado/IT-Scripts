# Charger le module ActiveDirectory
Import-Module -Name ActiveDirectory
$config = Import-PowerShellDataFile -Path "..\config.psd1"


# Spécifiez les informations de votre groupe AD et les détails de l'e-mail
$groupName = $config.ResetADPasswordGroupName
$smtpServer = $config.SMTPServer
$fromEmail = $config.FromEmail
$subject = $config.ResetADPasswordEmailSubject
$bodyTemplate = $config.ResetADPasswordEmailBodyTemplate
$samAccountNames = $config.ResetADPasswordSamAccountNames

# Définir le domaine AD
$Domain = "caf.cnaf.info"

if ($samAccountNames.Count -eq 0) {
    $samAccountName = Read-Host "Veuillez indiquer le SamAccountName du compte dont le mot de passe doit être modifié"
    $samAccountNames += $samAccountName
}

foreach ($samAccountName in $samAccountNames){
    # Génère un nouveau mot de passe aléatoire
    function GenerateRandomPassword {
        $length = 10
        $validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$*"
        $password = ""
        for ($i = 0; $i -lt $length; $i++) {
            $randomChar = Get-Random -Minimum 0 -Maximum $validChars.Length
            $password += $validChars[$randomChar]
        }
        return $password
    }

    # Récupère les membres du groupe AD dans le domaine spécifié
    $member = Get-ADGroupMember -Identity $groupName -Server $Domain | Where-Object {$_.objectClass -eq 'user' -and $_.SamAccountName -eq $samAccountName }

    # Parcours chaque membre, génère un nouveau mot de passe, le définit pour l'utilisateur et envoie un e-mail avec le mot de passe
    $user = Get-ADUser -Identity $member.SamAccountName -Server $Domain -Properties mail, otherMailbox
    $newPassword = GenerateRandomPassword

    $body = $bodyTemplate -f $newPassword

    $toList = @()
    if ($user.otherMailbox) { $toList += $user.otherMailbox }
    if ($user.mail)         { $toList += $user.mail }

    # Envoie un e-mail à l'utilisateur avec le nouveau mot de passe
    $sentOk = $false

    foreach ($to in $toList) {
        try {
            Send-MailMessage -SmtpServer $smtpServer -From $fromEmail -To $to -Subject $subject -Body $body -BodyAsHtml
            $sentOk = $true
            $toEmail = $to
            break   # Arrête après le premier envoi réussi
        }
        catch {
            Write-Host "Échec d'envoi vers $to, tentative suivante..."
        }
    }

    # Définit le nouveau mot de passe pour l'utilisateur
    if ($sentOk) {
        Set-ADAccountPassword -Identity $user.SamAccountName -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force) -Server $Domain
        Write-Host "Nouveau mot de passe envoyé par e-mail à l'utilisateur $($user.SamAccountName) à l'adresse : $($toEmail).."
    } else {
        Write-Host "Erreur, pas de mail renseigné dans l'AD"
    }
}


