<#
.SYNOPSIS
    Write a log entry to the DBLite log file.

.DESCRIPTION
    Writes a timestamped, leveled entry to today's DBLite log file. Also forwards formatted messages to the host or GUI as appropriate.

.PARAMETERS
    Level
        Log level (Debug, Info, Warning, Error). Mandatory.

    Message
        Text to write to the log. Mandatory.

    Timestamp
        Optional date/time for the entry; defaults to current time.

.EXAMPLE
    Write-DBLiteLog -Level Info -Message "Database initialized." -Timestamp (Get-Date)
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

.PARAMETERS
    BasePath
        Optional base path for the logs folder. Defaults to <module root>\logs.

.RETURNS
    String: full path to today's log file.
#>
function Initialize-LogFile {
    param(
        [string] $BasePath = (Join-Path $PSScriptRoot "..\..\..\logs")
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
    Builds a consistently formatted log string: "[LEVEL] yyyy-MM-dd HH:mm:ss: Message".

.PARAMETERS
    Level
        Log level (Debug, Info, Warning, Error). Mandatory.

    Timestamp
        Date/time used in the formatted entry. Mandatory.

    Message
        Message text to format. Mandatory.

.RETURNS
    String: the formatted log entry.

.EXAMPLE
    Format-LogEntry -Level Info -Timestamp (Get-Date) -Message "Service started"
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

<#
.SYNOPSIS
    Log an executed SQL query to the query history file.

.DESCRIPTION
    Adds an entry to queryhistory.json including database name, query text, execution status, affected rows, and timestamp.
    Logs query execution success or failure to the main DBLite log.

.PARAMETERS
    Database
        Name of the database where the query was executed. Mandatory.

    QueryText
        SQL text of the executed query. Mandatory.

    ExecutionStatus
        "Success" or "Failure". Defaults to "Success".

    AffectedRows
        Number of rows affected by the query. Defaults to 0.

    Timestamp
        Optional timestamp of execution. Defaults to current time.

.EXAMPLE
    Write-QueryLog -Database "TestDb" -QueryText "SELECT * FROM Users" -ExecutionStatus "Success" -AffectedRows 10

#>
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

        # Return an empty array if the file does not exist. Otherwise retrieve the contents
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

        # Create an object with given parameters and add it to the json
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

<#
.SYNOPSIS
    Ensure the query history file exists.

.DESCRIPTION
    Creates queryhistory.json if missing and logs its creation.
    Returns the full path to the query history file.

.PARAMETERS
    BasePath
        Optional full path to the query history file. Defaults to <module root>\logs\queryhistory.json.

.RETURNS
    String: full path to the query history file.
#>
function Initialize-QueryHistoryFile {
    param(
        [Parameter(Mandatory = $false)]
        [string] $BasePath = (Join-Path $PSScriptRoot "..\..\..\logs\queryhistory.json")
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
