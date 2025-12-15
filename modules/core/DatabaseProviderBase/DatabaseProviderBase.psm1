<#
.SYNOPSIS
Creates a new instance of a database provider base object.

.DESCRIPTION
Initializes a new database provider object using the IDatabaseProvider interface and assigns a name. This serves as a base object for implementing specific database providers.

.PARAMETERS
Name
    Optional name to assign to the database provider instance.

.RETURNS
A new database provider object implementing IDatabaseProvider.
#>
function New-DatabaseProviderBase {
    param(
        [string] $Name
    )

    $provider = New-IDatabaseProvider
    $provider.Name = $Name

    return $provider
}

Export-ModuleMember -Function New-DatabaseProviderBase
