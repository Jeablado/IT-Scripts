#Region Log
$logFolder = Join-Path $PSScriptRoot "log"
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
$logFile = Join-Path $logFolder "add_log.txt"
Start-Transcript -Path $logFile -Append
#EndRegion

Import-Module ActiveDirectory
Import-Module ExchangeOnlineManagement

#Region ConnexionExchange
# Se connecte à l'api de Exchange (pour pouvoir utiliser les commandes Update-DistributionGroupMember et Add-DistributionGroupMember)
$UtilisateurOffice365 = Get-Content -Path (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Identifiants\user.txt")
$MotDePasseUtilisateur = Get-Content -Path (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Identifiants\TENANTNAME.key") | ConvertTo-SecureString

$Cred = New-Object Management.Automation.PSCredential ($UtilisateurOffice365, $MotDePasseUtilisateur)

try{
	Connect-ExchangeOnline -Credential $Cred
}
catch {
	$_ | Out-File (Join-Path $PSScriptRoot "log\error_O365_log.txt") -Append
}
#EndRegion

#Region DataFromJson
$config = Get-Content (Join-Path $PSScriptRoot "Config.json") -Encoding UTF8 | ConvertFrom-Json
$filterKey = $config.ADSettings.filter.PSObject.Properties.Name
$filterValue = $config.ADSettings.filter.$filterKey
$filterString = "$filterKey -eq '$filterValue' -and DisplayName -notlike '*automate*'"
$properties = $config.ADSettings.Property
#EndRegion

$users = Get-ADUser -Filter $filterString -Property $properties

foreach ($entry in $config.UsersAttributesAndDLs) {
	$attributeType = $entry.ADAttributes.AttributeType
	$attributeData = $entry.ADAttributes.AttributeData
	$targetDLs = $entry.TargetDLs

	$matchingUsers = $users | Where-Object { $attributeData -contains $_.$attributeType }

	foreach ($dl in $targetDLs) {
        $currentMembers = Get-DistributionGroupMember -Identity $dl | Select-Object -ExpandProperty PrimarySmtpAddress

        foreach ($user in $matchingUsers) {
            if ($currentMembers -notcontains $user.EmailAddress) {
				Write-Host $user.EmailAddress
                Write-Host "$($user.DisplayName) ajouté à $dl"
                Add-DistributionGroupMember -Identity $dl -Member $user.EmailAddress
			}
		}
	}
}


Stop-Transcript