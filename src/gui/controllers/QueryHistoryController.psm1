Import-Module "$PSScriptRoot\..\..\..\modules\utils\Logger.psm1" -Force

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
