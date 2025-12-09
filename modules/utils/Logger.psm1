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
    Write-DBLiteLog [-Level <Debug|Info|Warning|Error>] -Timestamp <datetime> -Message <string> [-ToGui] [<CommonParameters>]

.PARAMETERS
    Level     - Log level (Debug, Info, Warning, Error)
    Timestamp - Date/time for the entry (DateTime); used for formatting
    Message   - Text to write to the log
    ToGui     - Switch; if present, forward the entry to the GUI log

.EXAMPLE
    Write-DBLiteLog -Level Info -Timestamp (Get-Date) -Message "Database initialized."

.RETURNS
    None (writes the formatted entry to the logfile).
#>
function Write-DBLiteLog {
    param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("Debug", "Info", "Warning", "Error")] $Level,
    [Parameter(Mandatory = $true, Position = 1)]
    [DateTime] $Timestamp = Get-Date,
    [Parameter(Mandatory = $true, Position = 2)]
    [string] $Message,
    [switch] $ToGui
    )

    $logFile = Initialize-LogFile
    $formattedEntry = Format-LogEntry -Level $Level -Timestamp $Timestamp -Message $Message
    Add-Content -Path $logFile -Value $formattedEntry
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

    $logFolder = Join-Path "$PSScriptRoot\..\..\logs"
    if (-not (Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory | Out-Null }
    
    # Construct logfile path and create file if it doesn't exist
    $today = Get-Date -Format "ddMMyyyy"
    $logFile = Join-Path $logFolder "dblite$today.log"

    if (-not (Test-Path $logFile)) { New-Item -Path $logFile -ItemType File | Out-Null }

    # Remove log files older than 30 days based on last write time
    $cutoff = (Get-Date).AddDays(-30)
    Get-ChildItem -Path $logFolder -Filter "dblite_*.log" | ForEach-Object {
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
    [string] $Message,
   )

    return "[$($Level.ToUpper())] $($Timestamp.ToString("yyyy-MM-dd HH:mm:ss")): $Message"
}

Export-ModuleMember -Function Write-DBLiteLog