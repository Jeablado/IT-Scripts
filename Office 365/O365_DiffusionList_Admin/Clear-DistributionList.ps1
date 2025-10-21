#Region Log
$logFolder = Join-Path $PSScriptRoot "log"
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
$logFile = Join-Path $logFolder "clear_log.txt"
Start-Transcript -Path $logFile -Append
#EndRegion

Import-Module ExchangeOnlineManagement

$config = Get-Content (Join-Path $PSScriptRoot "Config.json") | ConvertFrom-Json

foreach ($dl in $config.DLsToClear) {
    Write-Host "Vider la liste de diffusion : $dl"

    $members = Get-DistributionGroupMember -Identity $dl | Select-Object -ExpandProperty PrimarySmtpAddress

    if ($members.Count -gt 0) {
        foreach ($member in $members){
            Remove-DistributionGroupMember -Identity $dl -Member $member -Confirm:$false
            Write-Host "$member a été retiré de $dl"
        }
    } else {
        Write-Host "Aucun membre à retirer pour $dl"
    }
}
