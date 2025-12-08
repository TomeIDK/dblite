function Get-DBLiteAliases {
    $aliasFile = "$PSScriptRoot\..\..\config\aliases.json"

    if (-not (Test-Path $aliasFile)) {
        Write-Host "Alias file not found at $aliasFile. Continuing without aliases."
        return @{}
    }

    try {
        $json = Get-Content $aliasFile -Raw | ConvertFrom-Json -AsHashtable
        return $json
    }
    catch {
        Write-Warning "Failed to read aliases: $_"
        return @{}
    }
}

function Resolve-ConnectionString {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$InputString
    )

    $aliases = Get-DBLiteAliases
    if ($aliases.ContainsKey($InputString)) {
        return $aliases[$InputString]
    }
    else {
        Write-Host "No alias found for '$InputString'. Using it as the connection string."
        return $InputString
    }
}

Export-ModuleMember -Function Resolve-ConnectionString, Get-DBLiteAliases
