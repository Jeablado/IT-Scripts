@{	
	# AD
	AdDomain = ""
	AdSearchBase = "" # DN (Distinguished Name) AD des postes à requêter. Exemple "OU=...,DC=...,DC=..."
	
	# NETWORK
	networkAddress = "" #Identifiant de réseau (Partie commune à tous les hôtes du même sous-réseau). Exemple 10.20
	
	# EMAIL
	SMTPServer = "" 
	FromEmail = ""

	# PATHS
	# --Root
	RootDirectory = ".." # par défaut ".." pour remonter d'un niveau depuis l'emplacement des scripts, peut être un chemin absolu
	# ****Logs****
	# ----------Init
	ADExportLogPath = "\logs\ADExportLog.txt"
	PingLogPath = "\logs\PingLog.txt"
	MacFromArpLogPath = "\logs\MacFromArpLog.txt"
	# ----------Scripts
	WolShutDownLogPath = "\logs\WolShutDownLog.txt"
	GetComputersScreensLogPath = "\logs\GetComputersScreensLog.txt"

	# ****WorkingData****
	ADExportWorkingDataPath = "\WorkingData\ADExport.clixml"
	PingWorkingDataPath = "\WorkingData\Ping.clixml"
	MacFromArpWorkingDataPath = "\WorkingData\MacFromArp.clixml"
	ScreensWorkingDataPath = "\WorkingData\Screens.clixml"

	# ****OutputCSV****
	ScreensCsvPath = "\OutputCSV\ComputersScreens.csv"
	LoggedOnUsersCsvPath = "\OutputCSV\LoggedOnUsers.csv"

	# SCRIPT RESET-ADPASSWORD
	ResetADPasswordGroupName = ""
	ResetADPasswordEmailSubject = ""
	ResetADPasswordEmailBodyTemplate = ""
	ResetADPasswordSamAccountNames =  @("")
	
}