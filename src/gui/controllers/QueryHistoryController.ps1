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
        [string] $Database
    )

    $queryHistoryFile = Initialize-QueryHistoryFile

    if (-not (Test-Path $queryHistoryFile)) {
        Write-DBLiteLog -Level "Warning" -Message "Query history file not found: $queryHistoryFile"
        return @()
    }

    try {
        $queryHistory = Get-Content $queryHistoryFile -Raw | ConvertFrom-Json
        $results = $queryHistory | Where-Object { $_.Database -eq $Database }

        return @($results)
    }
    catch {
        Write-DBLiteLog -Level "Error" -Message "Failed to parse query history file: $($_.Exception.Message)"
        throw
    }
}
