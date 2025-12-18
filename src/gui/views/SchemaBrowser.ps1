function New-SchemaBrowser {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing


    function New-StyledButton {
        param(
            [Parameter(Mandatory = $true)]
            [string] $Name,
            [System.Drawing.Image] $Icon
        )

        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Name
        $btn.AutoSize = $true
        $btn.AutoSizeMode = "GrowAndShrink"
        $btn.Padding = [System.Windows.Forms.Padding]::new(10, 0, 10, 0)
        $btn.BackColor = [System.Drawing.Color]::FromArgb(50, 115, 220)
        $btn.ForeColor = [System.Drawing.Color]::White
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btn.TextAlign = "MiddleCenter"

        if ($Icon) {
            $btn.Image = $Icon
            $btn.ImageAlign = "MiddleLeft"
            $btn.TextImageRelation = "ImageBeforeText"
        }

        return $btn
    }


    # =====================
    # Top Bar
    # =====================
    $topBar = New-Object System.Windows.Forms.Panel
    $topBar.Height = 50
    $topBar.Dock = "Top"
    $topBar.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $topBar.Padding = [System.Windows.Forms.Padding]::new(10)


    # =====================
    # Title Label
    # =====================
    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Schema Browser"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(10, 10)


    # =====================
    # Buttons Container
    # =====================
    $btnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $btnPanel.FlowDirection = "RightToLeft"
    $btnPanel.Dock = "Fill"
    $btnPanel.WrapContents = $false
    $btnPanel.AutoSize = $true


    # =====================
    # Button Panel Buttons
    # =====================
    $btnExportCsv = New-StyledButton -Name "Export CSV"
    $btnExportJson = New-StyledButton -Name "Export JSON"


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
    # Layout Builder
    # =====================
    $viewLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $viewLayout.Dock = "Fill"
    $viewLayout.RowCount = 2
    $viewLayout.ColumnCount = 1

    $btnPanel.Controls.Add($btnExportCsv)
    $btnPanel.Controls.Add($btnExportJson)

    $topBar.Controls.Add($title)
    $topBar.Controls.Add($lastBackupLabel)
    $topBar.Controls.Add($btnPanel)

    $viewLayout.Controls.Add($topBar, 0, 0)
    $viewLayout.Controls.Add($cardsPanel, 0, 1)

    return $viewLayout

}

function New-TableSchemaCard {
    param(
        [Parameter(Mandatory = $true)]
        [string] $TableName,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable] $Columns
    )


    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing


    # =====================
    # Card container
    # =====================
    $card = New-Object System.Windows.Forms.Panel
    $card.AutoSize = $true
    $card.AutoSizeMode = 'GrowAndShrink'
    $card.Dock = 'Fill'
    $card.Padding = [System.Windows.Forms.Padding]::new(20, 5, 20, 5)
    $card.BackColor = [System.Drawing.Color]::White
    $card.BorderStyle = 'FixedSingle'


    # =====================
    # Header
    # =====================
    $header = New-Object System.Windows.Forms.TableLayoutPanel
    $header.ColumnCount = 2
    $header.RowCount = 1
    $header.Dock = 'Top'
    $header.AutoSize = $true
    $header.AutoSizeMode = 'GrowAndShrink'
    $header.Padding = [System.Windows.Forms.Padding]::new(0, 0, 0, 10)


    # =====================
    # Card Title
    # =====================
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $TableName
    $titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $titleLabel.AutoSize = $true
    $titleLabel.Dock = 'Left'
    $titleLabel.TextAlign = 'MiddleLeft'

    # =====================
    # Export Checkbox
    # =====================
    $exportCheckbox = New-Object System.Windows.Forms.CheckBox
    $exportCheckbox.Text = 'Export'
    $exportCheckbox.AutoSize = $true
    $exportCheckbox.Dock = 'Right'
    $exportCheckbox.TextAlign = 'MiddleRight'


    # =====================
    # Card Content
    # =====================
    $contentLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $contentLayout.Dock = 'Top'
    $contentLayout.ColumnCount = 3
    $contentLayout.RowCount = $Columns.Count + 1
    $contentLayout.AutoSize = $true
    $contentLayout.AutoSizeMode = 'GrowAndShrink'
    $contentLayout.CellBorderStyle = 'Single'
    $contentLayout.Padding = [System.Windows.Forms.Padding]::new(5)

    $headerNames = @("Column Name", "Type", "Constraint")
    for ($colIndex = 0; $colIndex -lt 3; $colIndex++) {
        $headerLabel = New-Object System.Windows.Forms.Label
        $headerLabel.Text = $headerNames[$colIndex]
        $headerLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
        $headerLabel.Dock = 'Fill'
        $headerLabel.TextAlign = 'MiddleCenter'
        $headerLabel.Padding = [System.Windows.Forms.Padding]::new(5)
        $headerLabel.Margin = [System.Windows.Forms.Padding]::new(0)
        $headerLabel.BackColor = [System.Drawing.Color]::FromArgb(50, 115, 220)
        $headerLabel.ForeColor = 'White'
        $headerLabel.AutoSize = $true
        $headerLabel.AutoEllipsis = $true
        $contentLayout.Controls.Add($headerLabel, $colIndex, 0)
    }

    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $col = $Columns[$i]

        $constraint = ''
        if ($col.IsPrimaryKey) { $constraint = 'PK' }
        elseif ($col.IsForeignKey) { $constraint = 'FK' }
        elseif ($col.IsUnique) { $constraint = 'UNIQUE' }
        elseif ($col.IsIndexed) { $constraint = 'INDEX' }

        $rowIndex = $i + 1

        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = $col.Name
        $nameLabel.Dock = 'Fill'
        $nameLabel.AutoSize = $true
        $nameLabel.TextAlign = 'MiddleLeft'
        $nameLabel.Padding = [System.Windows.Forms.Padding]::new(5)
        $nameLabel.Margin = [System.Windows.Forms.Padding]::new(0)

        $typeLabel = New-Object System.Windows.Forms.Label
        $typeLabel.Text = $col.DataType
        $typeLabel.Dock = 'Fill'
        $typeLabel.AutoSize = $true
        $typeLabel.TextAlign = 'MiddleLeft'
        $typeLabel.Padding = [System.Windows.Forms.Padding]::new(5)
        $typeLabel.Margin = [System.Windows.Forms.Padding]::new(0)

        $constraintLabel = New-Object System.Windows.Forms.Label
        $constraintLabel.Text = $constraint
        $constraintLabel.Dock = 'Fill'
        $constraintLabel.AutoSize = $true
        $constraintLabel.TextAlign = 'MiddleCenter'
        $constraintLabel.Padding = [System.Windows.Forms.Padding]::new(5)
        $constraintLabel.Margin = [System.Windows.Forms.Padding]::new(0)

        if ($i % 2 -eq 0) {
            $nameLabel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
            $typeLabel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
            $constraintLabel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
        }

        $contentLayout.Controls.Add($nameLabel, 0, $rowIndex)
        $contentLayout.Controls.Add($typeLabel, 1, $rowIndex)
        $contentLayout.Controls.Add($constraintLabel, 2, $rowIndex)
    }


    # =====================
    # Layout Builder
    # =====================
    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = 'Fill'
    $layout.RowCount = 2
    $layout.ColumnCount = 1
    $layout.AutoSize = $true
    $layout.AutoSizeMode = 'GrowAndShrink'

    $header.Controls.Add($titleLabel, 0, 0)
    $header.Controls.Add($exportCheckbox, 1, 0)

    $layout.Controls.Add($header, 0, 0)
    $layout.Controls.Add($contentLayout, 0, 1)

    $card.Controls.Add($layout)

    # Expose footer state
    $card.Tag = @{
        Export  = $exportCheckbox
        ViewBtn = $viewBtn
    }

    return $card
}


function New-ColumnRow {
    param(
        [string] $Name,
        [string] $Type,
        [string] $Constraint
    )

    $row = New-Object System.Windows.Forms.Panel
    $row.AutoSize = $true
    $row.Height = 24
    $row.Margin = [System.Windows.Forms.Padding]::new(0, 2, 0, 2)
    $row.BackColor = [System.Drawing.Color]::LightGray

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = $Name
    $nameLabel.AutoSize = $true
    $nameLabel.Location = [System.Drawing.Point]::new(0, 4)

    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Text = $Type
    $typeLabel.AutoSize = $true
    $typeLabel.Location = [System.Drawing.Point]::new(260, 4)

    $constraintLabel = New-Object System.Windows.Forms.Label
    $constraintLabel.Text = $Constraint
    $constraintLabel.AutoSize = $true
    $constraintLabel.Location = [System.Drawing.Point]::new(470, 4)
    $constraintLabel.TextAlign = 'MiddleCenter'

    $row.Controls.Add($nameLabel)
    $row.Controls.Add($typeLabel)
    $row.Controls.Add($constraintLabel)

    return $row
}
