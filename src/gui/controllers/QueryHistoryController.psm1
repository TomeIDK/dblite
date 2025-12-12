Import-Module PSSQLite
Import-Module "$PSScriptRoot\..\..\..\modules\utils\Logger.psm1" -Force

function Get-QueryHistory {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Database,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Success", "Failure")] $ExecutionStatus,
        [Parameter(Mandatory = $false)]
        [string] $BasePath = (Join-Path $PSScriptRoot "..\..\..\logs\query_history.sqlite")
    )

    Initialize-SQLiteDB

    $query = "SELECT * FROM QueryHistory WHERE Database = @Database"
    $params = @{ Database = $Database }

    if ($ExecutionStatus) {
        $query += " AND ExecutionStatus = @ExecutionStatus"
        $params.ExecutionStatus = $ExecutionStatus
    }

    $query += " ORDER BY Timestamp DESC"

    $history = Invoke-SqliteQuery -DataSource $BasePath -Query $query -SqlParameters $params

    return $history
}

Export-ModuleMember -Function Get-QueryHistory
