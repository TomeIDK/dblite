function New-Performance {
    param(
        [Parameter(Mandatory = $true)]
        $Provider
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # =====================
    # Helper function to create stat labels
    # =====================
    function New-StatLabel {
        param(
            [string] $text
        )

        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $lbl.AutoSize = $true
        $lbl.Margin = [System.Windows.Forms.Padding]::new(0, 0, 50, 20)

        return $lbl
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
    $title.Text = "Performance"
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
    # Group Box
    # =====================
    $dbGroupBox = New-Object System.Windows.Forms.GroupBox
    $dbGroupBox.Text = "$($Provider.Name) Runtime Stats"
    $dbGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $dbGroupBox.AutoSize = $true
    $dbGroupBox.AutoSizeMode = "GrowOnly"
    $dbGroupBox.MinimumSize = New-Object System.Drawing.Size(500, 200)
    $dbGroupBox.Location = New-Object System.Drawing.Point(10, 10)
    $dbGroupBox.Padding = [System.Windows.Forms.Padding]::new(10)
    $dbGroupBox.Margin = [System.Windows.Forms.Padding]::new(0, 0, 0, 25)


    # =====================
    # Group Box Flow Panel Layout
    # =====================
    $dbFlowPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $dbFlowPanel.Dock = "Fill"
    $dbFlowPanel.RowCount = 3
    $dbFlowPanel.ColumnCount = 2
    $dbFlowPanel.Padding = [System.Windows.Forms.Padding]::new(10)

    $querySpeedStatLabel = New-StatLabel "Avg Query Speed: -- ms"
    $queriesPerSecondStatLabel = New-StatLabel "Queries/sec: --"
    $connectionsStatLabel = New-StatLabel "Connections: --"
    $cpuStatLabel = New-StatLabel "CPU Usage: -- %"
    $memoryStatLabel = New-StatLabel "Memory Usage: -- MB"
    $diskStatLabel = New-StatLabel "Disk Usage: -- MB"


    # =====================
    # Group Box DBLite
    # =====================
    $dbliteGroupBox = New-Object System.Windows.Forms.GroupBox
    $dbliteGroupBox.Text = "DBLite Query Stats"
    $dbliteGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $dbliteGroupBox.AutoSize = $true
    $dbliteGroupBox.AutoSizeMode = "GrowOnly"
    $dbliteGroupBox.MinimumSize = New-Object System.Drawing.Size(500, 200)
    $dbliteGroupBox.Location = New-Object System.Drawing.Point(10, 10)
    $dbliteGroupBox.Padding = [System.Windows.Forms.Padding]::new(10)


    # =====================
    # Group Box Flow Panel Layout DBLite
    # =====================
    $dbliteFlowPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $dbliteFlowPanel.Dock = "Fill"
    $dbliteFlowPanel.RowCount = 3
    $dbliteFlowPanel.ColumnCount = 2
    $dbliteFlowPanel.Padding = [System.Windows.Forms.Padding]::new(10)


    $totalQueriesExecutedStatLabel = New-StatLabel "Total Queries Executed: --"
    $avgExecutionTimeStatLabel = New-StatLabel "Avg Execution Time: -- ms"


    # =====================
    # Layout Builder
    # =====================
    $viewLayout = New-Object System.Windows.Forms.TableLayoutPanel
    $viewLayout.Dock = "Fill"
    $viewLayout.RowCount = 4
    $viewLayout.ColumnCount = 1

    # $btnPanel.Controls.Add($btnHistory)
    # $btnPanel.Controls.Add($btnCreateBackup)

    $dbFlowPanel.Controls.Add($querySpeedStatLabel, 0, 0)
    $dbFlowPanel.Controls.Add($queriesPerSecondStatLabel, 0, 1)
    $dbFlowPanel.Controls.Add($connectionsStatLabel, 0, 2)
    $dbFlowPanel.Controls.Add($cpuStatLabel, 1, 0)
    $dbFlowPanel.Controls.Add($memoryStatLabel, 1, 1)
    $dbFlowPanel.Controls.Add($diskStatLabel, 1, 2)
    $dbGroupBox.Controls.Add($dbFlowPanel)

    $dbliteFlowPanel.Controls.Add($totalQueriesExecutedStatLabel, 0, 0)
    $dbliteFlowPanel.Controls.Add($avgExecutionTimeStatLabel, 0, 1)
    $dbliteGroupBox.Controls.Add($dbliteFlowPanel)

    $topBar.Controls.Add($title)
    $topBar.Controls.Add($btnPanel)

    $viewLayout.Controls.Add($topBar, 0, 0)
    $viewLayout.Controls.Add($dbGroupBox, 0, 1)
    $viewLayout.Controls.Add($dbliteGroupBox, 0, 2)

    return $viewLayout

}
