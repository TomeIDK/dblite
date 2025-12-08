param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ConnectionInput
)

# Import modules
Import-Module "$PSScriptRoot\modules\utils\AliasUtils.psm1" -Force
Import-Module "$PSScriptRoot\modules\core\IDatabaseProvider\IDatabaseProvider.psm1" -Force
Import-Module "$PSScriptRoot\modules\core\DatabaseProviderBase\DatabaseProviderBase.psm1" -Force
Import-Module "$PSScriptRoot\modules\providers\SqlServerProvider\SqlServerProvider.psm1" -Force
Import-Module "$PSScriptRoot\modules\gui\GetTablesGui\GetTablesGui.psm1" -Force

$connectionString = Resolve-ConnectionString $connectionInput
Write-Host "Using connection string: $connectionString"

$provider = New-SqlServerProvider

try {
    $provider.Connect($connectionString)
}
catch {
    Write-Warning $_
    exit
}

# Start GUI
Start-DBLiteGui -Provider $provider
