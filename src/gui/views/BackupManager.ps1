param(
    [Parameter(Mandatory = $true)]
    $Provider
)

Import-Module (Join-Path $PSScriptRoot "..\controllers\BackupManagerController.psm1") -Force

$Provider.GetBackupHistory() | Out-GridView -Title "DBLite | $($Provider.Name) Backup History"
