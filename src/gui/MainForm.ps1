Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ControllersPath = Join-Path $PSScriptRoot "\controllers"
$ViewsPath = Join-Path $PSScriptRoot "\views"

. (Join-Path $ControllersPath "\NavigationController.ps1")

function New-MainForm {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DBLite"
    $form.Size = New-Object System.Drawing.Size(1100, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"

    # Sidebar panel
    $Sidebar = New-Object System.Windows.Forms.Panel
    $Sidebar.Width = 120
    $Sidebar.Dock = "Left"
    $Sidebar.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
    $Sidebar.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    # Sidebar title
    $TitleLabel = New-Object System.Windows.Forms.Label
    $TitleLabel.Text = "DBLite"
    $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $TitleLabel.AutoSize = $true
    $TitleLabel.Location = New-Object System.Drawing.Point(10, 10)

    $Sidebar.Controls.Add($TitleLabel)

    # Content panel
    $ContentPanel = New-Object System.Windows.Forms.Panel
    $ContentPanel.Dock = "Fill"
    $ContentPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $ContentPanel.Padding = [System.Windows.Forms.Padding]::new(10, 0, 10, 0)

    # Navigation buttons
    $Tabs = @(
        "Query Editor",
        "Query History",
        "Schema Browser"
        "Backup Manager"
        "Performance"
        "Indexes"
    )

    # Navigation buttons
    $Y = 50
    $NavButtons = @{}

    function New-SidebarButton {
        param([string]$Text)
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Text
        $btn.Width = 120
        $btn.Height = 40
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $btn.TextAlign = "MiddleLeft"
        $btn.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
        $btn.Location = New-Object System.Drawing.Point(0, $Y)
        $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

        return $btn
    }

    foreach ($name in $Tabs) {
        $btn = New-SidebarButton -Text $name

        $Sidebar.Controls.Add($btn)
        $NavButtons[$name] = $btn

        $Y += 40
    }

    # Initialize Navigation Controller
    $Navigation = New-NavigationController -ContentPanel $ContentPanel -Buttons $NavButtons -ViewsPath $ViewsPath -Provider $Provider
    $Navigation.AttachEvents()

    # Compose form
    $form.Controls.AddRange(@($ContentPanel, $Sidebar))

    return $form
}

function Start-DBLiteGUI {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )

    $form = New-MainForm -Provider $Provider
    $form.ShowDialog()
}

