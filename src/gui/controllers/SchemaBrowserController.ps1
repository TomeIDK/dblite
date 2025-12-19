function Get-SelectedTablesToExport {
    param(
        [System.Windows.Forms.Control] $CardsPanel
    )

    foreach ($card in $CardsPanel.Controls) {
        if ($card.Tag.Export.Checked) { $card.Tag.TableName }
    }
}

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
