<#
.SYNOPSIS
Retrieves the names of tables selected for export from a panel of table cards.

.DESCRIPTION
Iterates through all controls in the specified panel, checks the Export property on each card's Tag,
and returns the TableName of cards marked for export.

.PARAMETER CardsPanel
The System.Windows.Forms.Control containing table card controls, each with a Tag property that includes an Export checkbox and TableName.

.EXAMPLE
PS> Get-SelectedTablesToExport -CardsPanel $TablesPanel
Returns the table names from cards in the panel that are checked for export.
#>
function Get-SelectedTablesToExport {
    param(
        [System.Windows.Forms.Control] $CardsPanel
    )

    foreach ($card in $CardsPanel.Controls) {
        if ($card.Tag.Export.Checked) { $card.Tag.TableName }
    }
}


<#
.SYNOPSIS
Exports the schema of specified tables to a CSV file.

.DESCRIPTION
Retrieves the schema for each table using the provided database provider and converts it into CSV format.
Each row includes table name, column name, data type, and key/uniqueness attributes.
Logs warnings if a table's schema cannot be retrieved or if no data is exported.
The CSV file is written to the specified file path.

.PARAMETER Provider
The database provider object used to retrieve table schemas. Must implement GetTableSchema.

.PARAMETER Tables
An array of table names whose schemas will be exported.

.PARAMETER FilePath
The file path where the CSV export will be saved.

.EXAMPLE
PS> Export-DbLiteTablesCsv -Provider $provider -Tables @("Users","Orders") -FilePath "C:\Exports\schemas.csv"
Exports the schemas of the Users and Orders tables to the specified CSV file.

.EXAMPLE
PS> Export-DbLiteTablesCsv -Provider $provider -Tables @("Products") -FilePath "C:\Exports\products_schema.csv"
Exports the schema of the Products table to a CSV file.
#>
function Export-DbLiteTablesCsv {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider,

        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $Tables,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $FilePath
    )

    $allRows = @()

    foreach ($table in $Tables) {
        $schema = $Provider.GetTableSchema($table)

        if (-not $schema) {
            Write-DBLiteLog -Level "Warning" -Message "Skipping table $table because schema could not be retrieved."
            continue
        }

        foreach ($column in $schema.Columns) {
            $allRows += [PSCustomObject]@{
                Table        = $table
                Name         = $column.Name
                DataType     = $column.DataType
                IsPrimaryKey = $column.IsPrimaryKey
                IsForeignKey = $column.IsForeignKey
                IsUnique     = $column.IsUnique
            }
        }

        if (-not $allRows) {
            Write-DBLiteLog -Level "Warning" -Message "No schemas exported."
            return
        }

        $allRows | ConvertTo-Csv -NoTypeInformation | Set-Content $FilePath

        Write-DBLiteLog -Level "Info" -Message "Schema CSV exported to $FilePath"
    }
}


<#
.SYNOPSIS
Exports the schema of specified tables to a JSON file.

.DESCRIPTION
Retrieves the schema for each table using the provided database provider and converts it into JSON format.
Logs warnings if a table's schema cannot be retrieved or if no schemas are exported.
The resulting JSON is written to the specified file path with full depth to preserve nested structures.

.PARAMETER Provider
The database provider object used to retrieve table schemas. Must implement GetTableSchema.

.PARAMETER Tables
An array of table names whose schemas will be exported.

.PARAMETER FilePath
The file path where the JSON export will be saved.

.EXAMPLE
PS> Export-DbLiteTablesJson -Provider $provider -Tables @("Users","Orders") -FilePath "C:\Exports\schemas.json"
Exports the schemas of the Users and Orders tables to the specified JSON file.

.EXAMPLE
PS> Export-DbLiteTablesJson -Provider $provider -Tables @("Products") -FilePath "C:\Exports\products_schema.json"
Exports the schema of the Products table to a JSON file.
#>
function Export-DbLiteTablesJson {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider,

        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $Tables,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $FilePath
    )

    $allSchemas = @()

    foreach ($table in $Tables) {
        $schema = $Provider.GetTableSchema($table)

        if (-not $schema) {
            Write-DBLiteLog -Level "Warning" -Message "Skipping table $table because schema could not be retrieved."
            continue
        }

        $allSchemas += $schema
    }

    if (-not $allSchemas) {
        Write-DBLiteLog -Level "Warning" -Message "No schemas exported."
        return
    }

    $allSchemas | ConvertTo-Json -Depth 10 | Set-Content $FilePath

    Write-DBLiteLog -Level "Info" -Message "Schema JSON exported to $FilePath"
}
