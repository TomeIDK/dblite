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
Get-ChildItem "$src\gui" -Recurse -Filter *.ps1 |
ForEach-Object { . $_ }



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
