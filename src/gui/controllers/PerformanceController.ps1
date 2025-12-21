function Get-QueryHistoryStats {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Database,

        [Parameter(Mandatory = $false)]
        [string] $FilePath = "$PSScriptRoot\..\..\..\logs\queryhistory.json"
    )

    # Load JSON
    if (-not (Test-Path $FilePath)) {
        throw "Query history file not found: $FilePath"
    }

    $allData = Get-Content $FilePath -Raw | ConvertFrom-Json

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
