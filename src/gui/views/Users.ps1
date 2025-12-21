function New-Users {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )


    $Provider.GetUsers() | Out-GridView -Title "DBLite | $($Provider.Name) Users"
}
