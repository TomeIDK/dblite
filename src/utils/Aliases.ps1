<#
.SYNOPSIS
Retrieves DBLite connection string aliases from a JSON file.

.DESCRIPTION
Loads a JSON file containing database connection aliases and returns them as a hashtable. If the file does not exist, it creates a default aliases.json file with instructions and returns an empty hashtable. Includes logging for creation, reading, or errors during the process. Useful for managing named database connections in DBLite scripts.

.PARAMETER AliasFileLocation
Path to the aliases JSON file. Defaults to "$PSScriptRoot\..\..\config\aliases.json". Must point to a valid JSON file or a writable directory if the file needs to be created.

.EXAMPLE
PS> $aliases = Get-DBLiteAliases
Reads the default aliases file and returns a hashtable of database aliases.

.EXAMPLE
PS> $aliases = Get-DBLiteAliases -AliasFileLocation "C:\DBLite\config\aliases.json"
Reads the aliases from a custom location instead of the default path.

.EXAMPLE
PS> $aliases["MyDatabase"]
Returns the connection string associated with the alias "MyDatabase".

.OUTPUTS
Hashtable of alias names to connection strings. Returns an empty hashtable if the file is missing or cannot be read.
#>
function Get-DBLiteAliases {
    param(
        [string] $AliasFileLocation = "$PSScriptRoot\..\..\config\aliases.json"
    )

    $aliasFile = $AliasFileLocation
    $aliasFolder = Split-Path $aliasFile

    # Ensure config folder exists
    if (-not (Test-Path $aliasFolder)) {
        Write-DBLiteLog -Level "Info" -Message "Config folder not found at $aliasFolder. Creating it."
        New-Item -Path $aliasFolder -ItemType Directory | Out-Null
    }

    # Ensure alias file exists
    if (-not (Test-Path $aliasFile)) {
        Write-DBLiteLog -Level "Warning" -Message "Alias file not found at $aliasFile. Creating aliases.json at this location."
        New-Item -Path $aliasFile -ItemType File -Value '{ "comment": "Use double backslashes to escape backslashes in JSON strings.", "MyDatabase": "Connection string for your database" }' | Out-Null
        Write-DBLiteLog -Level "Info" -Message "Created new alias file at $aliasFile."
        return @{}
    }

    # Read and convert aliases
    try {
        $json = Get-Content $aliasFile -Raw | ConvertFrom-Json -AsHashtable
        return $json
    }
    catch {
        Write-DBLiteLog -Level "Warning" -Message "Failed to read aliases: $_"
        return @{}
    }
}


<#
.SYNOPSIS
Resolves a database connection string from a DBLite alias or returns the input string as-is.

.DESCRIPTION
Checks if the provided input matches a named alias from the DBLite aliases JSON file. If a matching alias exists, returns the associated connection string. If no alias is found, returns the input string unchanged. Logs the resolution result. Useful for scripts that accept either connection strings or aliases.

.PARAMETER InputString
The alias name or direct database connection string to resolve. Mandatory parameter.

.EXAMPLE
PS> $conn = Resolve-ConnectionString -InputString "MyDatabase"
Resolves the alias "MyDatabase" to its connection string.

.EXAMPLE
PS> $conn = Resolve-ConnectionString "Server=localhost;Database=Test;User Id=sa;Password=pass;"
Returns the input string as-is since it does not match any alias.

.OUTPUTS
String containing the resolved connection string.

.INPUTS
String. Pipeline input is not supported.
#>
function Resolve-ConnectionString {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$InputString
    )

    # Get aliases and resolve
    $aliases = Get-DBLiteAliases
    if ($aliases.ContainsKey($InputString)) {
        Write-DBLiteLog -Level "Info" -Message "Resolved alias '$InputString'."
        return $aliases[$InputString]
    }
    else {
        Write-DBLiteLog -Level "Info" -Message "No alias found for '$InputString'. Using input as connection string."
        return $InputString
    }
}
