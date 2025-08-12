param (
    [string[]]$Servers,
    [switch]$Recurse,
    [string]$TaskPath = "\"
)

if (-not $Servers) {
    $Servers = (Import-Csv -Path ".\serverList.csv").ServerName
}

$results = [System.Collections.Generic.List[Object]]::new()

function Get-ScheduledTaskFolders {
    param (
        [string]$Server,
        [string]$TaskPath = "\"
    )

    Write-Host "Connecting to $Server with TaskPath $TaskPath"
    $taskService = New-Object -ComObject "Schedule.Service"
    $taskService.Connect($Server)

    $startFolder = $taskService.GetFolder($TaskPath)
    $folderList = @()

    function Recurse-Folder {
        param(
            $folder,
            [ref]$folderListRef
        )

        Write-Host "Checking folder: $($folder.Path)"
        $tasks = @()
        try {
            $tasks = $folder.GetTasks(0)
        } catch {
            Write-Host "No tasks in folder: $($folder.Path)"
        }

        if ($tasks.Count -gt 0) {
            Write-Host "Found tasks in folder: $($folder.Path)"
            $folderListRef.Value += $folder.Path
        }

        $subFolders = $folder.GetFolders(0)
        foreach ($subFolder in $subFolders) {
            Recurse-Folder -folder $subFolder -folderListRef $folderListRef
        }
    }

    Recurse-Folder -folder $startFolder -folderListRef ([ref]$folderList)

    $folderList = $folderList | ForEach-Object {
        # Si le chemin ne termine pas par '\', on l'ajoute
        if (-not $_.EndsWith('\')) {
            $_ + '\'
        }
        else {
            $_
        }
    }
    return $folderList | Sort-Object -Unique
}

foreach ($server in $Servers) {
    try {
        if ($Recurse) {
            # Récupérer tous les dossiers avec COM API
            $folders = Get-ScheduledTaskFolders -Server $server -TaskPath $TaskPath
            Write-Output $folders
        }
        else {
            # Si pas récursif, on ne traite que le dossier racine ou celui indiqué
            $folders = @($TaskPath)
        }

        foreach ($folder in $folders) {
            try {
                $tasks = Get-ScheduledTask -CimSession $server -TaskPath $folder -ErrorAction Stop
            }
            catch {
                Write-Warning "Erreur lors de la récupération des tâches sur $server dans $folder : $_"
                continue
            }

            foreach ($task in $tasks) {
                try {
                    $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -CimSession $server

                    # Construction description des triggers (plusieurs triggers possibles)
                    $triggerDescriptions = ($task.Triggers | ForEach-Object { $_.ToString() }) -join "; "

                    $taskObject = [PSCustomObject]@{
                        Server                = $server
                        # Onglet général
                        Name                  = $task.TaskName
                        Path                  = $task.TaskPath
                        Author                = $task.Author
                        Description           = $task.Description
                        Date                  = $task.Date

                        RunAs                 = $task.Principal.UserId
                        LogonType             = $task.Principal.LogonType
                        RunLevel              = $task.Principal.RunLevel

                        # Onglet Déclencheur
                        Triggers              = $triggerDescriptions

                        # Actions
                        ActionExecute         = $task.Actions.Execute
                        ActionArguments       = $task.Actions.Arguments
                        ActionWorkingDirectory= $task.Actions.WorkingDirectory

                        # Onglet Etat
                        State                 = $task.State

                        # Infos complémentaires
                        LastRunTime           = $info.LastRunTime
                        LastTaskResult        = $info.LastTaskResult
                        NextRunTime           = $info.NextRunTime
                        NumberOfMissedRuns    = $info.NumberOfMissedRuns
                    }

                    $results.Add($taskObject)
                }
                catch {
                    Write-Warning "Erreur pour la tâche '$($task.TaskName)' sur $server : $_"
                }
            }
        }
    }
    catch {
        Write-Warning "Erreur de connexion à $server : $_"
        continue
    }
}

$results | Export-Csv -Path ".\ScheduledTasks.csv" -NoTypeInformation -Encoding UTF8