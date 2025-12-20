function New-Indexes {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )


    $Provider.GetIndexes() | Out-GridView -Title "DBLite | $($Provider.Name) Indexes"
}
