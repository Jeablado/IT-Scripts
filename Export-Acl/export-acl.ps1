param (
    [switch]$Recurse,
	[int]$MaxDepth = 0 
)

$parentPaths = (Import-Csv -Path .\parentPaths.csv).Path

$aclList = @()

foreach ($parentPath in $parentPaths) {
    if (($Recurse) -or ($MaxDepth -gt 0)) {
        if ($MaxDepth -gt 0) {
			#Récursivité limitée
            $directories = Get-ChildItem -Path $parentPath -Directory -Recurse -Depth $MaxDepth
        }
        else {
			#Récursivité sans limite
            $directories = Get-ChildItem -Path $parentPath -Directory -Recurse
        }
    }
    else {
		#Sans récursivité
        $directories = Get-ChildItem -Path $parentPath -Directory
    }

    foreach ($directory in $directories) {
		$directory.FullName
		$acls = Get-Acl $directory.FullName

		foreach ($access in $acls.Access) {
			$aclList += [PSCustomObject]@{
				Path                = $directory.FullName
				IdentityReference   = $access.IdentityReference
				AccessControlType   = $access.AccessControlType
				FileSystemRights    = $access.FileSystemRights
			}
		}
	}
}
# Export en CSV
$aclList | Export-Csv -Path ".\export.csv" -NoTypeInformation -Encoding UTF8