<#
.SYNOPSIS
Retrieves the query history for a specified database.

.DESCRIPTION
Loads the query history from the queryhistory.json file and filters entries for the specified database.
If the file does not exist, a warning is logged and an empty array is returned.
Logs errors if the file cannot be parsed.

.PARAMETER Database
The name of the database for which to retrieve query history.

.EXAMPLE
PS> Get-QueryHistory -Database "TestDB"
Returns all query history entries for the "TestDB" database from the default query history file.
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
