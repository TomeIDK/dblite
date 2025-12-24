$src = Join-Path $PSScriptRoot '\src'

# Core
Get-ChildItem "$src\core" -Filter *.ps1 |
ForEach-Object { . $_ }

# Utils
Get-ChildItem "$src\utils" -Filter *.ps1 |
ForEach-Object { . $_ }

# Providers
Get-ChildItem "$src\providers" -Recurse -Filter *.ps1 |
ForEach-Object { . $_ }

# GUI
. "$src\gui\Components.ps1"
. "$src\gui\MainForm.ps1"

# Controllers
Get-ChildItem "$src\gui\controllers" -Filter *.ps1 |
ForEach-Object { . $_ }

# Views
Get-ChildItem "$src\gui\views" -Filter *.ps1 |
ForEach-Object { . $_ }

# Make functions used in click handlers global
$Global:SaveSavedQuery = ${function:Save-SavedQuery}
$Global:AddListBoxSavedQueries = ${function:Add-ListBoxSavedQueries}


<#
.SYNOPSIS
Starts the DBLite application with a specified database connection.

.DESCRIPTION
Initializes a database connection using the provided connection string or alias,
logs the connection attempt, and launches the DBLite GUI.
Handles connection errors by logging and throwing exceptions.
This function is the main entry point for running the DBLite application.

.PARAMETER ConnectionInput
The connection string or saved connection alias used to connect to the database.
This parameter is mandatory and must be a valid SQL Server connection string or alias.

.EXAMPLE
PS> Start-DBLite -ConnectionInput "Server=localhost;Database=TestDB;Integrated Security=True"
Connects to the specified database and opens the DBLite GUI.

.EXAMPLE
PS> Start-DBLite -ConnectionInput "MySavedAlias"
Uses a saved connection alias to connect and starts the GUI.
#>
function Start-DBLite {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ConnectionInput
    )

    $connectionString = Resolve-ConnectionString $connectionInput
    Write-DBLiteLog -Level "Info" -Message "Connected using provided connection string"

    $provider = New-SqlServerProvider

    try {
        $provider.Connect($connectionString)
    }
    catch {
        Write-DBLiteLog -Level "Error" -Message "Could not connect to database. See log for details: $_"
        throw
    }

    # Start GUI
    Start-DBLiteGUI -Provider $provider
}

Export-ModuleMember -Function Start-DBLite
