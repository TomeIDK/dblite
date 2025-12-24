<#
.SYNOPSIS
Creates a new base database provider with a specified name.

.DESCRIPTION
Generates a new provider object using New-IDatabaseProvider and assigns it a name.
This serves as a base object for actual database provider implementations.

.PARAMETER Name
The name to assign to the new provider.

.EXAMPLE
PS> $provider = New-DatabaseProviderBase -Name "SQLServerProvider"
Creates a new base provider object named "SQLServerProvider".
#>
function New-DatabaseProviderBase {
    param(
        [string] $Name
    )

    $provider = New-IDatabaseProvider
    $provider.Name = $Name

    return $provider
}
