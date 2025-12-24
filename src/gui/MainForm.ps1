<#
.SYNOPSIS
Creates the main form for the DBLite application with sidebar navigation.

.DESCRIPTION
Initializes a Windows Forms application with a fixed-size main window containing a sidebar and content panel.
Sidebar buttons correspond to various views (Query Editor, Query History, Schema Browser, Backup Manager, Performance, Indexes, Users).
Navigation is handled via a NavigationController which dynamically loads view scripts and manages button events.
The form is pre-configured with font styles, colors, and positioning.

.PARAMETER Provider
The database provider object to pass to views. Used for retrieving schemas, query history, and performing other database operations.

.EXAMPLE
PS> $form = New-MainForm -Provider $provider
Creates and returns a configured main DBLite form for the specified provider. The returned form can be shown via `$form.ShowDialog()`.
#>
function New-MainForm {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $ViewsPath = Join-Path $PSScriptRoot "\views"

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
        "Users"
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
Creates a navigation controller to manage loading views and button events in the main form.

.DESCRIPTION
Provides methods to dynamically load view scripts into a TableLayoutPanel and attach click events to sidebar navigation buttons.
Handles disposing of previous views (except for persistent views like Query History, Indexes, and Users).
Supports dynamic function-based loading for views that implement New-<ViewName>.

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
PSCustomObject: Navigation controller with LoadView and AttachEvents methods for managing dynamic view loading and button clicks.

.EXAMPLE
PS> $nav = New-NavigationController -ContentPanel $ContentPanel -Buttons $NavButtons -ViewsPath $ViewsPath -Provider $provider
Creates a navigation controller object to manage view switching and button events for the main form.
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
        if ($null -ne $this.CurrentView -and $ViewName -ne "Query History" -and $ViewName -ne "Indexes" -and $ViewName -ne "Users") {
            $this.ContentPanel.Controls.Clear()
            $this.CurrentView.Dispose()
        }

        # Convert view name to function name
        $funcName = "New-$($ViewName -replace ' ', '')"

        # Call the function to get the view object
        if (Get-Command $funcName -ErrorAction SilentlyContinue) {
            $view = & $funcName -Provider $Provider
        }
        else {
            $view = New-Object System.Windows.Forms.Label
            $view.Text = "$ViewName view not implemented yet."
            $view.Font = New-Object System.Drawing.Font("Segoe UI", 12)
            $view.AutoSize = $true
            $view.Location = New-Object System.Drawing.Point(20, 20)
        }


        if ($ViewName -ne "Query History" -and $ViewName -ne "Indexes" -and $ViewName -ne "Users") {
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
Starts the DBLite GUI application for the given database provider.

.DESCRIPTION
Initializes the main form using New-MainForm, sets the application icon if available,
and opens the form as a modal dialog.
Logs a warning if the application icon cannot be found.

.PARAMETER Provider
The database provider object to pass to the GUI. Required for retrieving data and interacting with the database.

.EXAMPLE
PS> Start-DBLiteGUI -Provider $provider
Launches the DBLite GUI for the specified provider, displaying the main form as a modal window.
#>
function Start-DBLiteGUI {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )

    $iconPath = Join-Path $PSScriptRoot "assets\icon.ico"
    $form = New-MainForm -Provider $Provider

    if (Test-Path $iconPath) {
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
    }
    else {
        Write-DBLiteLog -Level "Warning" -Message "Application icon not found at $iconPath"
    }

    $form.ShowDialog()
}

