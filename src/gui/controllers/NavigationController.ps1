function New-NavigationController {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$ContentPanel,

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

        # Dispose previous view
        if ($null -ne $this.CurrentView) {
            $this.ContentPanel.Controls.Remove($this.CurrentView)
            $this.CurrentView.Dispose()
            $this.CurrentView = $null
        }

        # Check if view exists
        $file = Join-Path $this.ViewsPath "$($ViewName -replace ' ', '').ps1"
        Write-Host "[NavigationController] Loading view: $ViewName from $file"

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

        $view.Dock = "Fill"
        $this.ContentPanel.Controls.Add($view)
        $this.CurrentView = $view

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
