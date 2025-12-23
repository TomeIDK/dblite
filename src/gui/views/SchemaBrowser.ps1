function New-SchemaBrowser {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing


    # =====================
    # Top Bar
    # =====================
    $topBar = New-TopBar -Title "Performance" -WithButtons



    # =====================
    # Card Flow Layout Panel
    # =====================
    $cardsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $cardsPanel.FlowDirection = 'TopDown'
    $cardsPanel.WrapContents = $false
    $cardsPanel.Dock = 'Fill'
    $cardsPanel.AutoScroll = $true
    $cardsPanel.Padding = [System.Windows.Forms.Padding]::new(5)

    $tables = $Provider.GetTables()

    foreach ($table in $tables) {
        $card = New-TableSchemaCard `
            -TableName $table.Name `
            -Columns   $table.Columns

        $cardsPanel.Controls.Add($card)
    }


    # =====================
    # Export All Checkbox
    # =====================
    $exportAllCheckbox = New-Object System.Windows.Forms.CheckBox
    $exportAllCheckbox.Text = "Export All"
    $exportAllCheckbox.AutoSize = $true
    $exportAllCheckbox.Dock = "Right"
    $exportAllCheckbox.Tag = $cardsPanel

    $exportAllCheckbox.Add_CheckedChanged({
            $cardsPanelCopy = $this.Tag
            $checked = $this.Checked

            foreach ($card in $cardsPanelCopy.Controls) {
                $chk = $card.Tag.Export
                if ($chk) {
                    $chk.Invoke({ $chk.Checked = $checked })
                }
            }
        })


    # =====================
    # Button Panel Buttons
    # =====================
    $btnExportCsv = New-ButtonPanelButton -Name "Export CSV"
    $btnExportCsv.Tag = $cardsPanel
    $btnExportCsv.Add_Click({
            $cardsPanelCopy = $this.Tag
            $tables = Get-SelectedTablesToExport -CardsPanel $cardsPanelCopy
            if (-not $tables) {
                [System.Windows.Forms.MessageBox]::Show('Please select at least one table to export.', 'No tables selected', 'OK', 'Warning')
                return
            }


            $dialog = New-Object System.Windows.Forms.SaveFileDialog
            $dialog.RestoreDirectory = $true
            $dialog.FileName = "$($Provider.Name.ToLower())_schema.csv"
            $dialog.Filter = 'JSON Files (*.csv)|*.csv'

            if ($dialog.ShowDialog() -eq 'OK') {
                $filePath = $dialog.FileName

                if (-not $filePath.EndsWith('.csv')) {
                    $filePath += '.csv'
                }

                Export-DbLiteTablesCsv -Provider $Provider -Tables $tables -FilePath $filePath

                [System.Windows.Forms.MessageBox]::Show("Export completed: $filePath", "Export Success", 'OK', 'Information')
            }



        })

    $btnExportJson = New-ButtonPanelButton -Name "Export JSON"
    $btnExportJson.Tag = $cardsPanel
    $btnExportJson.Add_Click({
            $cardsPanelCopy = $this.Tag
            $tables = Get-SelectedTablesToExport -CardsPanel $cardsPanelCopy

            if (-not $tables) {
                [System.Windows.Forms.MessageBox]::Show('Please select at least one table to export.', 'No tables selected', 'OK', 'Warning')
                return
            }

            $dialog = New-Object System.Windows.Forms.SaveFileDialog
            $dialog.RestoreDirectory = $true
            $dialog.FileName = "$($Provider.Name.ToLower())_schema.json"
            $dialog.Filter = 'JSON Files (*.json)|*.json'

            if ($dialog.ShowDialog() -eq 'OK') {
                $filePath = $dialog.FileName

                if (-not $filePath.EndsWith('.json')) {
                    $filePath += '.json'
                }

                Export-DbLiteTablesJson -Provider $Provider -Tables $tables -FilePath $filePath

                [System.Windows.Forms.MessageBox]::Show("Export completed: $filePath", "Export Success", 'OK', 'Information')
            }
        })


    # =====================
    # Layout Builder
    # =====================
    $viewLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $viewLayout.Dock = "Fill"
    $viewLayout.RowCount = 2
    $viewLayout.ColumnCount = 1

    $topBar.Tag.ButtonPanel.Controls.AddRange(@($btnExportCsv, $btnExportJson, $exportAllCheckbox))

    $viewLayout.Controls.Add($topBar, 0, 0)
    $viewLayout.Controls.Add($cardsPanel, 0, 1)

    return $viewLayout

}
