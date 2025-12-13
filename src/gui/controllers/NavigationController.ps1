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
        if ($null -ne $this.CurrentView -and $ViewName -ne "Query History" -and $ViewName -ne "Backup Manager") {
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

        if ($ViewName -ne "Query History" -and $ViewName -ne "Backup Manager") {
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
