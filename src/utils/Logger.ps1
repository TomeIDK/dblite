<#
.SYNOPSIS
Writes a log entry to the DBLite log file with a specified severity level.

.DESCRIPTION
Logs messages to a centralized DBLite log file, formatting each entry with a timestamp and severity level. Depending on the severity, it also outputs the message to the PowerShell host using the appropriate stream: Write-Error for errors, Write-Warning for warnings, and Write-Verbose for info or debug messages. Automatically initializes the log file if it does not exist.

.PARAMETER Level
The severity level of the log entry. Must be one of "Debug", "Info", "Warning", or "Error".

.PARAMETER Timestamp
Optional. The timestamp to include with the log entry. Defaults to the current date and time.

.PARAMETER Message
The message text to log. Mandatory parameter.

.EXAMPLE
PS> Write-DBLiteLog -Level "Info" -Message "Database connection established."
Logs an informational message to the DBLite log file and outputs it as verbose.

.EXAMPLE
PS> Write-DBLiteLog -Level "Error" -Message "Failed to execute query."
Logs an error message to the DBLite log file and writes it to the error stream.
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
        "Info" { Write-Verbose $formattedEntry }
        Default { Write-Verbose $formattedEntry }
    }
}


<#
.SYNOPSIS
Initializes the DBLite log file for the current day and manages old log cleanup.

.DESCRIPTION
Ensures the log directory exists and creates a new log file for the current date if it does not already exist. Automatically deletes log files older than 30 days to maintain log retention. Returns the full path to the current log file.

.PARAMETER BasePath
Optional. The base directory where log files are stored. Defaults to "$PSScriptRoot\..\..\logs".

.EXAMPLE
PS> Initialize-LogFile
Creates or returns today's log file in the default log directory, deleting any logs older than 30 days.

.EXAMPLE
PS> Initialize-LogFile -BasePath "C:\MyLogs"
Uses a custom log directory instead of the default.

.OUTPUTS
String. The full path to the initialized log file.
#>
function Initialize-LogFile {
    param(
        [string] $BasePath = (Join-Path $PSScriptRoot "..\..\logs")
    )

    $logFolder = $BasePath
    if (-not (Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory | Out-Null }

    # Construct logfile path and create file if it doesn't exist
    $today = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path $logFolder "dblite-$today.log"

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
Formats a log message with timestamp and severity level.

.DESCRIPTION
Generates a standardized string for logging purposes including the timestamp, log level, and message content. Intended for use by logging functions like Write-DBLiteLog.

.PARAMETER Level
Mandatory. The severity of the log message. Valid values are "Debug", "Info", "Warning", "Error".

.PARAMETER Timestamp
Mandatory. The date and time to include in the log entry.

.PARAMETER Message
Mandatory. The text of the log message to format.

.EXAMPLE
PS> Format-LogEntry -Level "Info" -Timestamp (Get-Date) -Message "Connection established."
Returns a string like: "2025-12-24 18:00:01 [INFO]: Connection established."

.EXAMPLE
PS> Format-LogEntry -Level "Error" -Timestamp (Get-Date) -Message "Failed to connect to database."
Returns a string like: "2025-12-24 18:05:10 [ERROR]: Failed to connect to database."

.OUTPUTS
String. The formatted log entry.
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

    return "$($Timestamp.ToString("yyyy-MM-dd HH:mm:ss")) [$($Level.ToUpper())]: $Message"
}


<#
.SYNOPSIS
Logs SQL query execution details to a JSON history file.

.DESCRIPTION
Records information about a query executed against a database, including its text, execution status, affected rows, execution time, and timestamp. Intended for auditing and performance tracking of queries. The log is stored in a JSON file managed by Initialize-QueryHistoryFile. Side effects include writing to disk.

.PARAMETER Database
Mandatory. The name of the database against which the query was executed.

.PARAMETER QueryText
Mandatory. The text of the SQL query that was executed.

.PARAMETER ExecutionStatus
Optional. The result of the query execution. Valid values are "Success" or "Failure". Default is "Success".

.PARAMETER AffectedRows
Optional. The number of rows affected by the query. Default is 0.

.PARAMETER ExecutionTime
Optional. The execution duration of the query in milliseconds. Default is 0.

.PARAMETER Timestamp
Optional. The date and time when the query was executed. Default is the current date and time.

.EXAMPLE
PS> Write-QueryLog -Database "TestDB" -QueryText "SELECT * FROM Users"
Logs a successful query execution for the "TestDB" database.

.EXAMPLE
PS> Write-QueryLog -Database "SalesDB" -QueryText "DELETE FROM Orders WHERE Id=5" -ExecutionStatus "Success" -AffectedRows 1 -ExecutionTime 35
Logs a DELETE query execution with affected row count and execution time.

.OUTPUTS
None. Function writes log entries to disk and outputs nothing.

.INPUTS
None. Does not accept pipeline input.
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

        [Parameter(Mandatory = $false, Position = 4)]
        [int] $ExecutionTime = 0,

        [Parameter(Mandatory = $false)]
        [DateTime] $Timestamp = (Get-Date)

    )

    try {
        $queryHistoryFile = Initialize-QueryHistoryFile

        # Return an empty array if the file does not exist. Otherwise retrieve the contents
        if (-not (Test-Path $queryHistoryFile)) {
            $queryHistory = @()
        }
        else {
            $raw = Get-Content $queryHistoryFile -Raw

            if ([string]::IsNullOrWhiteSpace($raw) -or $raw.Trim() -eq '{}') {
                $queryHistory = @()
            }
            else {
                $queryHistory = $raw | ConvertFrom-Json
                if ($queryHistory -isnot [System.Collections.IEnumerable]) {
                    $queryHistory = @($queryHistory)
                }
            }
        }

        # Create an object with given parameters and add it to the json
        $entry = [PSCustomObject]@{
            Database        = $Database
            QueryText       = $QueryText
            ExecutionStatus = $ExecutionStatus
            AffectedRows    = $AffectedRows
            ExecutionTime   = $ExecutionTime
            Timestamp       = $Timestamp
        }

        $queryHistory += $entry

        $queryHistory | ConvertTo-Json | Set-Content $queryHistoryFile -Encoding UTF8


        Write-DBLiteLog -Level "Info" -Message "Logged query execution: '$QueryText' Status: $ExecutionStatus AffectedRows: $AffectedRows ExecutionTime: $($ExecutionTime)ms"
    }
    catch {
        Write-DBLiteLog -Level "Error" -Message "Failed to log query execution: $($_.Exception.Message)"
    }
}


<#
.SYNOPSIS
Initializes the JSON file used to store SQL query execution history.

.DESCRIPTION
Ensures that a query history file exists at the specified location. If the file does not exist, it creates an empty JSON file. The file is used by Write-QueryLog to store query execution details. Side effects include creating a file on disk and logging the initialization process.

.PARAMETER BasePath
Optional. The full path to the query history file. Default is "<script root>\..\..\logs\queryhistory.json".

.EXAMPLE
PS> Initialize-QueryHistoryFile
Creates the default query history file at the default logs folder if it does not exist.

.EXAMPLE
PS> Initialize-QueryHistoryFile -BasePath "C:\DBLite\logs\queryhistory.json"
Creates the query history file at a custom path if it does not exist.

.OUTPUTS
String. The full path to the query history file.
#>
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
