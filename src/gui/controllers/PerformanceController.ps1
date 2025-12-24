<#
.SYNOPSIS
Generates statistics from the query history for a specified database.

.DESCRIPTION
Reads the query history JSON file, filters for successful queries related to the specified database,
and calculates key metrics including total queries, average execution time, fastest and slowest queries,
total execution time, and timestamp of the last executed query. Logs warnings or errors if the history
file is missing or malformed.

.PARAMETER Database
The name of the database for which to generate query statistics. Only successful queries are considered.

.PARAMETER FilePath
Optional path to the query history JSON file. Defaults to the standard queryhistory.json log file in the logs folder.

.EXAMPLE
PS> Get-QueryHistoryStats -Database "TestDB"
Generates query statistics for the "TestDB" database using the default query history file.

.EXAMPLE
PS> Get-QueryHistoryStats -Database "TestDB" -FilePath "C:\Logs\queryhistory.json"
Generates query statistics for "TestDB" using a custom query history file.
#>
function Get-QueryHistoryStats {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Database,

        [Parameter(Mandatory = $false)]
        [string] $FilePath = "$PSScriptRoot\..\..\..\logs\queryhistory.json"
    )

    # Load JSON
    if (-not (Test-Path $FilePath)) {
        Write-DBLiteLog -Level "Warning" -Message "Query history file not found: $FilePath"
        return $null
    }

    try {
        $allData = Get-Content $FilePath -Raw | ConvertFrom-Json
    }
    catch {
        Write-DBLiteLog -Level "Error" -Message "Failed to parse query history file: $($_.Exception.Message)"
        throw
    }

    # Filter by database and successful queries
    $filtered = $allData | Where-Object {
        $_.Database -eq $Database -and $_.ExecutionStatus -eq "Success"
    }

    if (-not $filtered) {
        Write-DBLiteLog -Level "Info" -Message "No successful queries found for database '$Database'."
        return $null
    }

    $queryCount = $filtered.Count
    $avgTime = ($filtered | Measure-Object -Property ExecutionTime -Average).Average
    $totalTime = ($filtered | Measure-Object -Property ExecutionTime -Sum).Sum
    $fastest = ($filtered | Measure-Object -Property ExecutionTime -Minimum).Minimum
    $slowest = ($filtered | Measure-Object -Property ExecutionTime -Maximum).Maximum
    $lastExec = ($filtered | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp.ToString('yyyy-MM-dd HH:mm:ss')

    return [PSCustomObject]@{
        Database               = $Database
        QueryCount             = $queryCount
        AverageExecutionTimeMs = [math]::Round($avgTime, 2)
        TotalExecutionTimeMs   = [math]::Round($totalTime, 2)
        FastestQueryMs         = $fastest
        SlowestQueryMs         = $slowest
        LastExecutedQuery      = $lastExec
    }
}
