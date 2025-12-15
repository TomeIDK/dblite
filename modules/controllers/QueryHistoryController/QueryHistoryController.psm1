Import-Module "$PSScriptRoot\..\..\..\modules\utils\Logger\Logger.psm1" -Force

<#
.SYNOPSIS
Retrieves the history of executed queries for a specific database.

.DESCRIPTION
Loads query execution history from the JSON history file and returns entries matching the specified database. Optionally, results can be filtered by execution status ("Success" or "Failure"). Logs are handled by the Logger module.

.PARAMETERS
Database
    Name of the database to retrieve query history for. Mandatory.

ExecutionStatus
    Optional filter for the query execution status. Accepts "Success" or "Failure".

.RETURNS
Array of objects representing executed queries, including database name, query text, execution time, and status.
#>
function Get-QueryHistory {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Database,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Success", "Failure")] $ExecutionStatus
    )

    $queryHistoryFile = Initialize-QueryHistoryFile

    $queryHistory = Get-Content $queryHistoryFile -Raw | ConvertFrom-Json
    $results = $queryHistory | Where-Object { $_.Database -eq $Database }

    return $results
}

Export-ModuleMember -Function Get-QueryHistory
