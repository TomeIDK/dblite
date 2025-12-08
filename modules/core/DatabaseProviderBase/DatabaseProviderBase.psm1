function New-DatabaseProviderBase {
    param(
        [string] $Name
    )

    $provider = New-IDatabaseProvider
    $provider.Name = $Name

    return $provider
}

Export-ModuleMember -Function New-DatabaseProviderBase
