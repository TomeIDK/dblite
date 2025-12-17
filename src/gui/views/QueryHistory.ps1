function New-QueryHistory {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )


    Get-QueryHistory -Database $Provider.Name | Out-GridView -Title "DBLite | $($Provider.Name) Query History"
}
