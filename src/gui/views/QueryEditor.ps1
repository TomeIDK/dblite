function New-QueryEditor {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )


    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $AssetsPath = Join-Path $PSScriptRoot "..\assets"


    # =====================
    # Top bar
    # =====================
    $topBar = New-TopBar -Title "Query Editor" -WithButtons


    # =====================
    # SQL input textbox
    # =====================
    $sqlBox = New-Object System.Windows.Forms.TextBox
    $sqlBox.Multiline = $true
    $sqlBox.ScrollBars = "Vertical"
    $sqlBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $sqlBox.Dock = "Top"
    $sqlBox.Height = 200
    $sqlBox.Padding = [System.Windows.Forms.Padding]::new(10)
    $sqlBox.Text = "SELECT * FROM Products;"
    $sqlBox.BorderStyle = "FixedSingle"


    # =====================
    # Saved queries title
    # =====================
    $savedTitle = New-Object System.Windows.Forms.Label
    $savedTitle.Text = "Saved queries"
    $savedTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $savedTitle.Dock = "Top"
    $savedTitle.AutoSize = $true


    # =====================
    # Saved queries listbox
    # =====================
    $savedList = New-Object System.Windows.Forms.ListBox
    $savedList.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $savedList.Dock = "Fill"
    $savedList.BorderStyle = "FixedSingle"
    $savedList.DisplayMember = "Name"
    $savedList.ValueMember = "Sql"
    $savedList.Add_DoubleClick({
            if ($savedList.SelectedItem) {
                $sqlBox.Text = $savedList.SelectedItem.Sql
            }
        }.GetNewClosure())
    Add-ListBoxSavedQueries -ListBox $savedList

    # =====================
    # Buttons
    # =====================
    $btnRun = New-ButtonPanelButton -Name "Run" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "run-icon-white-small.png")))

    # Run the query in the textbox
    $btnRun.Add_Click({
            $dt = $Provider.RunQuery($sqlBox.Text)
            $dt | Out-GridView -Title "DBLite | Query Results"
        }.GetNewClosure())

    $btnSave = New-ButtonPanelButton -Name "Save Query" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "save-icon-white-small.png")))

    # Open a modal prompting the user to enter a name to save the query in the text box
    $btnSave.Add_Click({
            $modal = New-Object System.Windows.Forms.Form
            $modal.Text = "Save Query"
            $modal.Text = $Title
            $modal.StartPosition = "CenterParent"
            $modal.FormBorderStyle = "FixedDialog"
            $modal.MaximizeBox = $false
            $modal.MinimizeBox = $false
            $modal.AutoSize = $true
            $modal.AutoSizeMode = 'GrowAndShrink'
            $modal.Icon = [System.Drawing.SystemIcons]::Question

            $layout = New-Object System.Windows.Forms.TableLayoutPanel
            $layout.AutoSize = $true
            $layout.AutoSizeMode = 'GrowAndShrink'
            $layout.Padding = 10
            $layout.ColumnCount = 1
            $layout.RowCount = 3
            $layout.Dock = 'Fill'

            $label = New-Object System.Windows.Forms.Label
            $label.Text = "Enter a name for your query"
            $label.AutoSize = $true

            $nameBox = New-Object System.Windows.Forms.TextBox
            $nameBox.Width = 300
            $nameBox.Margin = '0,4,0,10'

            $buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
            $buttonPanel.AutoSize = $true
            $buttonPanel.FlowDirection = 'LeftToRight'
            $buttonPanel.Anchor = 'None'
            $buttonPanel.Padding = '0,5,0,0'

            $btnOk = New-Object System.Windows.Forms.Button
            $btnOk.Text = "Save"
            $btnOk.Font = New-Object System.Drawing.Font(
                $btnOk.Font.FontFamily,
                $btnOk.Font.Size,
                [System.Drawing.FontStyle]::Bold
            )

            $btnCancel = New-Object System.Windows.Forms.Button
            $btnCancel.Text = "Cancel"

            $modal.AcceptButton = $btnOk
            $modal.CancelButton = $btnCancel

            # Save the query under the given name
            $btnOk.Add_Click({
                    $name = $nameBox.Text.Trim()
                    if ($name) {
                        & $Global:SaveSavedQuery -Name $name -Sql $sqlBox.Text
                        & $Global:AddListBoxSavedQueries -ListBox $savedList

                        $modal.DialogResult = [System.Windows.Forms.DialogResult]::OK
                        $modal.Close()
                    }
                    else {
                        [System.Windows.Forms.MessageBox]::Show(
                            "Name cannot be empty.",
                            "Validation",
                            'OK',
                            'Warning'
                        )
                    }
                })

            # Cancel saving the query
            $btnCancel.Add_Click({
                    $modal.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                    $modal.Close()
                })

            $buttonPanel.Controls.AddRange(@($btnOk, $btnCancel))
            $layout.Controls.Add($label, 0, 0)
            $layout.Controls.Add($nameBox, 0, 1)
            $layout.Controls.Add($buttonPanel, 0, 2)

            $modal.Controls.Add($layout)
            $modal.Add_Shown({ $nameBox.Focus() })
            $modal.ShowDialog()

        }.GetNewClosure())

    $btnClear = New-ButtonPanelButton -Name "Clear" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "trash-icon-white-small.png")))

    # Clear the text box
    $btnClear.Add_Click({
            $sqlBox.Text = ""
        }.GetNewClosure())

    $topBar.Tag.ButtonPanel.Controls.AddRange(@($btnRun, $btnSave, $btnClear))


    # =====================
    # Layout builder
    # =====================
    $viewLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $viewLayout.Dock = "Fill"
    $viewLayout.RowCount = 5
    $viewLayout.ColumnCount = 1

    $viewLayout.Controls.Add($topBar, 0, 0)
    $viewLayout.Controls.Add($sqlBox, 0, 1)
    $viewLayout.Controls.Add($savedTitle, 0, 2)
    $viewLayout.Controls.Add($savedList, 0, 3)


    # Return the panel as the view
    return $viewLayout
}
