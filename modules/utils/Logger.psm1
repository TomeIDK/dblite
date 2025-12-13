<#
.SYNOPSIS
    Logging utilities for the DBLite module.

.DESCRIPTION
    Provides functions to write and format log entries and ensure the logs folder and today's logfile exist.
    Exported functions: Write-DBLiteLog, Initialize-LogFile, Format-LogEntry.

.SYNTAX
    Import-Module <PathTo>\Logger.psm1
#>


<#
.SYNOPSIS
    Write a log entry to the DBLite log file.

.DESCRIPTION
    Writes a timestamped, leveled entry to today's DBLite log file and optionally forwards the formatted entry to the GUI.

.SYNTAX
    Write-DBLiteLog [-Level <Debug|Info|Warning|Error>] -Message <string> [-Timestamp <datetime>] [<CommonParameters>]

.PARAMETERS
    Level     - Log level (Debug, Info, Warning, Error)
    Message   - Text to write to the log
    Timestamp - Date/time for the entry (DateTime); used for formatting

.EXAMPLE
    Write-DBLiteLog -Level Info -Timestamp (Get-Date) -Message "Database initialized."

#>
function Write-DBLiteLog {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Debug", "Info", "Warning", "Error")] $Level,
        [Parameter(Mandatory = $false)]
        [DateTime] $Timestamp = (Get-Date),
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Message
    )

    $logFile = Initialize-LogFile
    $formattedEntry = Format-LogEntry -Level $Level -Timestamp $Timestamp -Message $Message
    Add-Content -Path $logFile -Value $formattedEntry

    switch ($Level) {
        "Error" { Write-Error $formattedEntry }
        "Warning" { Write-Warning $formattedEntry }
        "Info" { Write-Host $formattedEntry }
        Default { Write-Debug $formattedEntry }
    }
}

<#
.SYNOPSIS
    Ensure the DBLite logs folder and today's log file exist.

.DESCRIPTION
    Creates the logs directory if missing, creates today's logfile (dbliteDDMMYYYY.log),
    and removes log files older than 30 days.

.SYNTAX
    Initialize-LogFile

.RETURNS
    String: full path to today's logfile.
#>
function Initialize-LogFile {
    param(
        [string] $BasePath = (Join-Path $PSScriptRoot "\..\..\logs")
    )

    $logFolder = $BasePath
    if (-not (Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory | Out-Null }

    # Construct logfile path and create file if it doesn't exist
    $today = Get-Date -Format "ddMMyyyy"
    $logFile = Join-Path $logFolder "dblite$today.log"

    if (-not (Test-Path $logFile)) { New-Item -Path $logFile -ItemType File | Out-Null }

    # Remove log files older than 30 days based on last write time
    $cutoff = (Get-Date).AddDays(-30)
    Get-ChildItem -Path $logFolder -Filter "dblite*.log" | ForEach-Object {
        if ($_.LastWriteTime -lt $cutoff) {
            Remove-Item $_.FullName -Force
        }
    }

    return $logFile
}

<#
.SYNOPSIS
    Format a timestamped, leveled log entry.

.DESCRIPTION
    Builds a consistent formatted log string for disk or forwarding:
    "[LEVEL] yyyy-MM-dd HH:mm:ss: Message".

.SYNTAX
    Format-LogEntry [-Level <Debug|Info|Warning|Error>] -Timestamp <datetime> -Message <string>

.PARAMETERS
    Level     - Log level (Debug, Info, Warning, Error)
    Timestamp - Date/time used in the formatted entry
    Message   - Message text to format

.EXAMPLE
    Format-LogEntry -Level Info -Timestamp (Get-Date) -Message "Service started"

.RETURNS
    String: the formatted log entry.
#>
function Format-LogEntry {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Debug", "Info", "Warning", "Error")] $Level,

        [Parameter(Mandatory = $true, Position = 1)]
        [DateTime] $Timestamp,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $Message
    )

    return "[$($Level.ToUpper())] $($Timestamp.ToString("yyyy-MM-dd HH:mm:ss")): $Message"
}

function Write-QueryLog {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Database,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $QueryText,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("Success", "Failure")] $ExecutionStatus = "Success",

        [Parameter(Mandatory = $false, Position = 3)]
        [int] $AffectedRows = 0,

        [Parameter(Mandatory = $false)]
        [DateTime] $Timestamp = (Get-Date)

    )

    try {
        $queryHistoryFile = Initialize-QueryHistoryFile

        if (-not (Test-Path $queryHistoryFile)) {
            $queryHistory = @()
        } else {
            $raw = Get-Content $queryHistoryFile -Raw

            if ([string]::IsNullOrWhiteSpace($raw) -or $raw.Trim() -eq '{}') {
                $queryHistory = @()
            } else {
                $queryHistory = $raw | ConvertFrom-Json
                if ($queryHistory -isnot [System.Collections.IEnumerable]) {
                    $queryHistory = @($queryHistory)
                }
            }
        }

        $entry = [PSCustomObject]@{
            Database = $Database
            QueryText = $QueryText
            ExecutionStatus = $ExecutionStatus
            AffectedRows = $AffectedRows
            Timestamp = $Timestamp
        }

        $queryHistory += $entry

        $queryHistory | ConvertTo-Json | Set-Content $queryHistoryFile -Encoding UTF8


        Write-DBLiteLog -Level "Info" -Message "Logged query execution: '$QueryText' Status: $ExecutionStatus AffectedRows: $AffectedRows"
    }
    catch {
        Write-DBLiteLog -Level "Error" -Message "Failed to log query execution: $($_.Exception.Message)"
    }
}

function Initialize-QueryHistoryFile {
    param(
        [Parameter(Mandatory = $false)]
        [string] $BasePath = (Join-Path $PSScriptRoot "..\..\logs\queryhistory.json")
    )

    # Create the file if it doesn't exist
    if (-not (Test-Path $BasePath)) {
        try {
            New-Item -Path $BasePath -ItemType File -Value '{}' | Out-Null
            Write-DBLiteLog -Level "Info" -Message "Initialized query history file at $BasePath"
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to initialize query history file at $($BasePath): $_"
        }
    }

    return $BasePath
}

Export-ModuleMember -Function Write-DBLiteLog, Initialize-LogFile, Format-LogEntry, Write-QueryLog, Initialize-QueryHistoryFile
