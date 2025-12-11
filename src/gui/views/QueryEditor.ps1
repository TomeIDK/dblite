param(
    [Parameter(Mandatory = $true)]
    $Provider
)


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Import-Module (Join-Path $PSScriptRoot "..\controllers\QueryEditorController.psm1") -Force
Import-Module "$PSScriptRoot\..\..\..\modules\utils\Logger.psm1" -Force

$AssetsPath = Join-Path $PSScriptRoot "..\assets"

# Main view panel
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Fill"
$panel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)


# Top bar
$topBar = New-Object System.Windows.Forms.Panel
$topBar.Height = 50
$topBar.Dock = "Top"
$topBar.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$topBar.Padding = [System.Windows.Forms.Padding]::new(10)

# Title label
$title = New-Object System.Windows.Forms.Label
$title.Text = "Query Editor"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(10, 10)

# Buttons container
$btnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$btnPanel.FlowDirection = "RightToLeft"
$btnPanel.Dock = "Fill"
$btnPanel.WrapContents = $false
$btnPanel.AutoSize = $true

# Button factory
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

# SQL input textbox
$sqlBox = New-Object System.Windows.Forms.TextBox
$sqlBox.Multiline = $true
$sqlBox.ScrollBars = "Vertical"
$sqlBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$sqlBox.Dock = "Top"
$sqlBox.Height = 200
$sqlBox.Padding = [System.Windows.Forms.Padding]::new(10)
$sqlBox.Text = "SELECT * FROM Users;"


# Saved queries title
$savedTitle = New-Object System.Windows.Forms.Label
$savedTitle.Text = "Saved queries"
$savedTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$savedTitle.Dock = "Top"
$savedTitle.AutoSize = $true


# Saved queries list
$savedList = New-Object System.Windows.Forms.ListBox
$savedList.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$savedList.Dock = "Fill"
$savedList.Height = ($savedList.Items.Count * $savedList.ItemHeight) + 2
Add-ListBoxSavedQueries -ListBox $savedList

# Container for saved queries
$savedPanel = New-Object System.Windows.Forms.Panel
$savedPanel.Dock = "Fill"

# Buttons
$btnRun = New-StyledButton -Name "Run" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "run-icon-white-small.png")))
$btnRun.Add_Click({
        $Provider.RunQuery($sqlBox.Text) | Out-Null
    }.GetNewClosure())

$btnSave = New-StyledButton -Name "Save Query" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "save-icon-white-small.png")))
$btnSave.Add_Click({
        Write-Host "sqlBox text: " $sqlBox.Text
        $modal = New-Object System.Windows.Forms.Form
        $modal.Text = "Save Query"
        $modal.Size = New-Object System.Drawing.Size(350, 150)
        $modal.StartPosition = "CenterParent"
        $modal.FormBorderStyle = "FixedDialog"
        $modal.MaximizeBox = $false
        $modal.MinimizeBox = $false

        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Enter a name:"
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.AutoSize = $true

        $nameBox = New-Object System.Windows.Forms.TextBox
        $nameBox.Location = New-Object System.Drawing.Point(10, 35)
        $nameBox.Width = 300

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "OK"
        $btnOk.Location = New-Object System.Drawing.Point(140, 70)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancel"
        $btnCancel.Location = New-Object System.Drawing.Point(220, 70)

        $btnOk.Add_Click({
                $name = $nameBox.Text.Trim()
                if ($name) {
                    Save-SavedQuery -Name $name -Sql $sqlBox.Text
                    Add-ListBoxSavedQueries -ListBox $savedList
                    $modal.Close()
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("Name cannot be empty.")
                }
            })

        $btnCancel.Add_Click({
                $modal.Close()
            })

        $modal.Controls.Add($label)
        $modal.Controls.Add($nameBox)
        $modal.Controls.Add($btnOk)
        $modal.Controls.Add($btnCancel)

        $modal.ShowDialog()
    }.GetNewClosure())

$btnClear = New-StyledButton -Name "Clear" -Icon ([System.Drawing.Image]::FromFile((Join-Path $AssetsPath "trash-icon-white-small.png")))
$btnClear.Add_Click({
        $sqlBox.Text = ""
    }.GetNewClosure())

$btnPanel.Controls.AddRange(@($btnRun, $btnSave, $btnClear))


# Layout builder
$savedPanel.Controls.Add($savedList)
$savedPanel.Controls.Add($savedTitle)

$topBar.Controls.Add($title)
$topBar.Controls.Add($btnPanel)

$panel.Controls.Add($savedPanel)
$panel.Controls.Add($sqlBox)
$panel.Controls.Add($topBar)


# Return the panel as the view
return $panel
