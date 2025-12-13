param(
    [Parameter(Mandatory = $true)]
    $Provider
)

Import-Module (Join-Path $PSScriptRoot "..\controllers\QueryHistoryController.psm1") -Force

Get-QueryHistory -Database $Provider.Name | Out-GridView -Title "DBLite | $($Provider.Name) Query History"
