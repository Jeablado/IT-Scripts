$config = Import-PowerShellDataFile -Path "..\config.psd1"

$ADExportWorkingDataPath = $config.RootDirectory + $config.ADExportWorkingDataPath
$ADExportLogPath = $config.RootDirectory + $config.ADExportLogPath

# Début de Transcription
Start-Transcript -Append -Path $ADExportLogPath

# Chargement de la base AD
try {
	$allComputers = Get-ADComputer -SearchBase $config.AdSearchBase -Filter * -Properties *
} Catch {
	Write-Output "AD Base not found"
}

# Affichage des postes ajoutés dans le Log
Write-Output "Postes extraits de l'AD : $((@($allComputers)).Count)"
if ($allComputers.Count -gt 0){
	$allComputers | ForEach-Object { $_.Name }

	New-Item -ItemType Directory -Path (Split-Path $ADExportWorkingDataPath) -Force -ErrorAction SilentlyContinue | Out-Null
	$allComputers | Export-Clixml -Path $ADExportWorkingDataPath
}

Stop-Transcript

