Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ViewsPath = Join-Path $PSScriptRoot "\views"

<#
.SYNOPSIS
    Main GUI form and navigation controller for DBLite.

.DESCRIPTION
    Provides the main Windows Forms GUI including sidebar navigation, content panels, and view management.
    Handles dynamic loading of views, navigation button events, and integrates with a database provider.
    Exported functions: New-MainForm, New-NavigationController, Start-DBLiteGUI.

.SYNTAX
    Import-Module <PathTo>\MainForm.psm1
#>

<#
.SYNOPSIS
    Create the main DBLite GUI form.

.DESCRIPTION
    Initializes the main form with a sidebar, content panel, and navigation buttons.
    Integrates with a database provider object to display current database information.
    Dynamically loads views when navigation buttons are clicked.

.PARAMETERS
    Provider
        Database provider object to associate with the GUI. Mandatory.

.RETURNS
    System.Windows.Forms.Form: The initialized main form.
#>
function New-MainForm {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DBLite | $($Provider.Name)"
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
    $ContentPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $ContentPanel.Dock = "Fill"
    $ContentPanel.RowCount = 1
    $ContentPanel.ColumnCount = 1
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

<#
.SYNOPSIS
    Create a navigation controller for managing views and button events.

.DESCRIPTION
    Provides methods to load views into a TableLayoutPanel, dispose previous views when appropriate,
    and attach click events to sidebar navigation buttons. Supports dynamic loading of PS1 view scripts.

.PARAMETERS
    ContentPanel
        TableLayoutPanel where views will be loaded. Mandatory.

    Buttons
        Hashtable of sidebar buttons keyed by view names. Mandatory.

    ViewsPath
        Path to the folder containing view scripts. Mandatory.

    Provider
        Database provider object passed to views. Mandatory.

.RETURNS
    PSCustomObject: Navigation controller with LoadView and AttachEvents methods.
#>
function New-NavigationController {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TableLayoutPanel]$ContentPanel,

        [Parameter(Mandatory = $true)]
        [hashtable]$Buttons,

        [Parameter(Mandatory = $true)]
        [string]$ViewsPath,

        [Parameter(Mandatory = $true)]
        $Provider
    )

    $controller = [PSCustomObject]@{
        ContentPanel = $ContentPanel
        Buttons      = $Buttons
        ViewsPath    = $ViewsPath
        CurrentView  = $null
    }

    # Load view
    $controller | Add-Member -MemberType ScriptMethod -Name "LoadView" -Value {
        param(
            [string]$ViewName
        )

        # Dispose previous view, unless it is Query History
        if ($null -ne $this.CurrentView -and $ViewName -ne "Query History") {
            $this.ContentPanel.Controls.Clear()
            $this.CurrentView.Dispose()
        }

        # Check if view exists
        $file = Join-Path $this.ViewsPath "$($ViewName -replace ' ', '').ps1"

        if (Test-Path $file) {
            $view = & $file -Provider $Provider
        }
        else {
            $view = New-Object System.Windows.Forms.Label
            $view.Text = "$ViewName view not implemented yet."
            $view.Font = New-Object System.Drawing.Font("Segoe UI", 12)
            $view.AutoSize = $true
            $view.Location = New-Object System.Drawing.Point(20, 20)
        }

        if ($ViewName -ne "Query History") {
            $this.ContentPanel.Controls.Add($view, 0, 0)
            $this.CurrentView = $view
        }


        foreach ($key in $this.Buttons.Keys) {
            $this.Buttons[$key].BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
        }

        $this.Buttons[$ViewName].BackColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
    }

    # Attach event handlers to buttons
    $controller | Add-Member -MemberType ScriptMethod -Name "AttachEvents" -Value {
        $controller = $this

        foreach ($key in $this.Buttons.Keys) {
            $btn = $controller.Buttons[$key]

            $btn.Add_Click({
                    $controller.LoadView($key)
                }.GetNewClosure())
        }
    }
    return $controller
}

<#
.SYNOPSIS
    Start the DBLite GUI.

.DESCRIPTION
    Initializes the main form for the specified database provider and displays it as a modal dialog.
    Internally calls New-MainForm and shows the form.

.PARAMETERS
    Provider
        Database provider object to associate with the GUI. Mandatory.

.EXAMPLE
    Start-DBLiteGUI -Provider $sqlProvider
#>
function Start-DBLiteGUI {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )

    $form = New-MainForm -Provider $Provider
    $form.ShowDialog()
}

