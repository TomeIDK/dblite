function New-BackupManager {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $AssetsPath = Join-Path $PSScriptRoot "..\assets"

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
    $title.Text = "Backup Manager"
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
    # Last Backup Label
    # =====================
    $lastBackupLabel = New-Object System.Windows.Forms.Label
    $lastBackupLabel.Text = "Last backup: $($Provider.GetLatestBackup().ToString('dd/MM/yyyy HH:mm:ss'))"
    $lastBackupLabel.AutoSize = $true
    $lastBackupLabel.TextAlign = 'MiddleLeft'
    $lastBackupLabel.ForeColor = [System.Drawing.Color]::Gray
    $lastBackupLabel.Dock = 'Bottom'
    $lastBackupLabel.Padding = [System.Windows.Forms.Padding]::new(0, 8, 0, 8)


    # =====================
    # Warning Label
    # =====================
    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Text = 'Warning: Only use this if you know what you are doing.'
    $warningLabel.ForeColor = [System.Drawing.Color]::FromArgb(230, 170, 90)
    $warningLabel.Dock = 'Top'
    $warningLabel.AutoSize = $true
    $warningLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $warningLabel.Padding = [System.Windows.Forms.Padding]::new(0, 5, 0, 10)


    # =====================
    # Backup Settings Group
    # =====================
    $settingsGroup = New-Object System.Windows.Forms.GroupBox
    $settingsGroup.Text = 'Backup Settings'
    $settingsGroup.Dock = 'Top'
    $settingsGroup.Height = 180
    $settingsGroup.Padding = [System.Windows.Forms.Padding]::new(10)


    # =====================
    # Backup Path Label
    # =====================
    $pathLabel = New-Object System.Windows.Forms.Label
    $pathLabel.Text = 'Backup file:'
    $pathLabel.Location = '10,25'

    # =====================
    # Backup Path Textbox
    # =====================
    $pathTextBox = New-Object System.Windows.Forms.TextBox
    $pathTextBox.Location = '10,50'
    $pathTextBox.Width = 400
    $pathTextBox.ReadOnly = $true
    $pathTextBox.Text = Join-Path $env:USERPROFILE "Documents\DBLite\Backups\$($Provider.Name)\$($Provider.Name.ToLower()).bak"

    # =====================
    # Browse Button
    # =====================
    $browseBtn = New-Object System.Windows.Forms.Button
    $browseBtn.Text = 'Browse...'
    $browseBtn.Location = '420,48'

    # Open a file dialog to choose where to save the backup
    $browseBtn.Add_Click({
            $dialog = New-Object System.Windows.Forms.SaveFileDialog
            $dialog.RestoreDirectory = $true
            $dialog.FileName = "$($Provider.Name.ToLower())_backup.bak"
            $dialog.Filter = 'Backup Files (*.bak)|*.bak'
            if ($dialog.ShowDialog() -eq 'OK') {
                if (-not $dialog.FileName.EndsWith('.bak')) {
                    $pathTextBox.Text = "$($dialog.FileName).bak"
                }
                else {
                    $pathTextBox.Text = $dialog.FileName
                }
            }
        }.GetNewClosure())


    # =====================
    # Backup Type Label
    # =====================
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Text = 'Backup type:'
    $typeLabel.Location = '10,85'


    # =====================
    # Backup Type Combo Box
    # =====================
    $typeComboBox = New-Object System.Windows.Forms.ComboBox
    $typeComboBox.Location = '10,110'
    $typeComboBox.Width = 200
    $typeComboBox.DropDownStyle = 'DropDownList'
    $typeComboBox.Items.AddRange(@('Full', 'Differential'))
    $typeComboBox.SelectedIndex = 0
    $typeComboBox.AutoSize = $true


    # =====================
    # Compression Checkbox
    # =====================
    $compressionCheckbox = New-Object System.Windows.Forms.CheckBox
    $compressionCheckbox.Text = 'Enable compression'
    $compressionCheckbox.Location = '230,112'
    $compressionCheckbox.AutoSize = $true
    $compressionCheckbox.Checked = $true

    $edition = $Provider.GetEdition()
    if ($edition -like '*Express*') {
        $compressionCheckbox.Enabled = $false
        $compressionCheckbox.Checked = $false
        $compressionCheckbox.Text = "Enable compression (Not supported by $($edition))"
    }


    # =====================
    # Button Panel Buttons
    # =====================
    $btnCreateBackup = New-StyledButton -Name "Create Backup" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "add-icon-white-small.png")))

    # Open a modal to confirm creating a backup then save it
    $btnCreateBackup.Add_Click({
            if (-not $pathTextBox.Text) {
                [System.Windows.Forms.MessageBox]::Show('Please select a backup location.')
                return
            }
            $modal = New-Object System.Windows.Forms.Form
            $modal.Text = "Confirm Backup"
            $modal.AutoSize = $true
            $modal.AutoSizeMode = "GrowAndShrink"
            $modal.StartPosition = "CenterParent"
            $modal.FormBorderStyle = "FixedDialog"
            $modal.MaximizeBox = $false
            $modal.MinimizeBox = $false
            $modal.Icon = [System.Drawing.SystemIcons]::Question

            $modalLayout = New-Object System.Windows.Forms.TableLayoutPanel
            $modalLayout.AutoSize = $true
            $modalLayout.AutoSizeMode = "GrowAndShrink"
            $modalLayout.Padding = 10
            $modalLayout.ColumnCount = 1
            $modalLayout.RowCount = 3
            $modalLayout.Dock = 'Fill'

            $labelQuestion = New-Object System.Windows.Forms.Label
            $labelQuestion.Text = "Are you sure you want to create a database backup at the following location?"
            $labelQuestion.AutoSize = $true

            $labelPath = New-Object System.Windows.Forms.Label
            $labelPath.Text = $pathTextBox.Text
            $labelPath.TextAlign = "MiddleCenter"
            $labelPath.AutoSize = $true
            $labelPath.Anchor = "None"
            $labelPath.Margin = [System.Windows.Forms.Padding]::new(0, 8, 0, 12)
            $labelPath.ForeColor = [System.Drawing.Color]::DimGray
            $labelPath.Font = New-Object System.Drawing.Font(
                $labelPath.Font.FontFamily,
                $labelPath.Font.Size,
                [System.Drawing.FontStyle]::Italic
            )

            $buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
            $buttonPanel.AutoSize = $true
            $buttonPanel.FlowDirection = 'LeftToRight'
            $buttonPanel.Anchor = 'None'
            $buttonPanel.Padding = [System.Windows.Forms.Padding]::new(0, 5, 0, 0)
            $buttonPanel.Margin = [System.Windows.Forms.Padding]::new(0)

            $btnYes = New-Object System.Windows.Forms.Button
            $btnYes.Text = "Yes"
            $btnYes.Font = New-Object System.Drawing.Font(
                $btnYes.Font.FontFamily,
                $btnYes.Font.Size,
                [System.Drawing.FontStyle]::Bold
            )

            $btnNo = New-Object System.Windows.Forms.Button
            $btnNo.Text = "Cancel"

            # Create the backup in the selected location
            $btnYes.Add_Click({
                    $Provider.NewBackup($pathTextBox.Text, $typeComboBox.SelectedItem, $compressionCheckbox.Checked)
                    $modal.Close()
                })

            # Cancel the backup
            $btnNo.Add_Click({
                    $modal.Close()
                })

            $modal.AcceptButton = $btnYes
            $modal.CancelButton = $btnNo

            $buttonPanel.Controls.AddRange(@($btnYes, $btnNo))

            $modalLayout.Controls.Add($labelQuestion, 0, 0)
            $modalLayout.Controls.Add($labelPath, 0, 1)
            $modalLayout.Controls.Add($buttonPanel, 0, 2)
            $modal.Controls.Add($modalLayout)

            $modal.ShowDialog()
        }.GetNewClosure())

    $btnHistory = New-StyledButton -Name "History" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "history-icon-white-small.png")))

    # Open a DataGridView with backup history for this database
    $btnHistory.Add_Click({
            $Provider.GetBackupHistory() | Out-GridView -Title "DBLite | $($Provider.Name) Backup History"
        })

    # =====================
    # Layout Builder
    # =====================
    $viewLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $viewLayout.Dock = "Fill"
    $viewLayout.RowCount = 4
    $viewLayout.ColumnCount = 1

    $settingsGroup.Controls.AddRange(@(
            $pathLabel,
            $pathTextBox,
            $browseBtn,
            $typeLabel,
            $typeComboBox,
            $compressionCheckbox
        ))

    $btnPanel.Controls.Add($btnHistory)
    $btnPanel.Controls.Add($btnCreateBackup)

    $topBar.Controls.Add($title)
    $topBar.Controls.Add($lastBackupLabel)
    $topBar.Controls.Add($btnPanel)

    $viewLayout.Controls.Add($topBar, 0, 0)
    $viewLayout.Controls.Add($warningLabel, 0, 1)
    $viewLayout.Controls.Add($settingsGroup, 0, 2)
    $viewLayout.Controls.Add($lastBackupLabel, 0, 3)

    return $viewLayout
}
