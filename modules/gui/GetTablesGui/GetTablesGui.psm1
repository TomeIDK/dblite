Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data

function Start-DBLiteGui {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $Provider
    )




    # $tables = $Provider.GetTables()

    # $form = New-Object System.Windows.Forms.Form
    # $form.Text = "DBLite Tables (SQL Server)"
    # $form.Size = New-Object System.Drawing.Size(400, 300)

    # $listBox = New-Object System.Windows.Forms.ListBox
    # $listBox.Size = New-Object System.Drawing.Size(300, 200)
    # $listBox.Location = New-Object System.Drawing.Point(40, 30)
    # $listBox.Items.AddRange($tables)

    # $form.Controls.Add($listBox)

    # $form.Add_FormClosing({
    #         $Provider.Disconnect()
    #     })

    # $form.ShowDialog()
}

Export-ModuleMember -Function Start-DBLiteGui
