<#
.SYNOPSIS
    Read the DBLite alias file and return aliases as a hashtable.

.DESCRIPTION
    Ensures the aliases.json file exists in the module config folder. If missing, creates a default aliases.json and logs the action.
    Attempts to read and convert the JSON to a hashtable. On failure, logs a warning and returns an empty hashtable.

.RETURNS
    Hashtable: Mapping of alias names to their respective connection strings.
#>
function Get-DBLiteAliases {
    param(
        [string] $AliasFileLocation = "$PSScriptRoot\..\..\config\aliases.json"
    )

    $aliasFile = $AliasFileLocation

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
    Resolve an input alias or return the input as a connection string.

.DESCRIPTION
    Looks up the provided input string in the aliases hashtable (from aliases.json).
    If an alias exists, returns the mapped connection string and logs the resolution.
    If not found, logs that the input will be used as-is and returns the original input.

.PARAMETERS
    InputString
        The alias name or connection string to resolve. Mandatory.

.RETURNS
    String: The resolved connection string (either from aliases.json or the original input).

.EXAMPLE
    Resolve-ConnectionString -InputString "MyDatabase"
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
