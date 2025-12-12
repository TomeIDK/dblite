param(
    [Parameter(Mandatory = $true)]
    $Provider
)


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Import-Module (Join-Path $PSScriptRoot "..\controllers\QueryHistoryController.psm1") -Force

# Top bar
$topBar = New-Object System.Windows.Forms.Panel
$topBar.Height = 50
$topBar.Dock = "Top"
$topBar.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$topBar.Padding = [System.Windows.Forms.Padding]::new(10)

# Title label
$title = New-Object System.Windows.Forms.Label
$title.Text = "Query History"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(10, 10)

# Call your function to get the history
$history = Get-QueryHistory -Database $Provider.Name
$history | Out-GridView

# Layout builder
$viewLayout = New-Object System.Windows.Forms.TableLayoutPanel
$viewLayout.Dock = "Fill"
$viewLayout.RowCount = 2
$viewLayout.ColumnCount = 1

$topBar.Controls.Add($title)

$viewLayout.Controls.Add($topBar, 0, 0)

return $viewLayout
