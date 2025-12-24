<#
.SYNOPSIS
Retrieves saved queries from a JSON file.

.DESCRIPTION
Loads saved queries from a JSON configuration file and returns them as a hashtable.
If the file does not exist, it creates an empty savedqueries.json file.
Logs messages for successful loading, creation, or errors during reading.

.PARAMETER FilePath
Optional path to the saved queries JSON file. Defaults to the standard savedqueries.json in the config folder.

.EXAMPLE
PS> Get-SavedQueries
Loads saved queries from the default configuration file.

.EXAMPLE
PS> Get-SavedQueries -FilePath "C:\MyConfig\savedqueries.json"
Loads saved queries from a custom file path.
#>
function Get-SavedQueries {
    param(
        [Parameter(Mandatory = $false)]
        [string] $FilePath = (Join-Path $PSScriptRoot "..\..\..\config\savedqueries.json")
    )

    # Check if file already exists and retrieve its contents. Create the file if not
    if (Test-Path $FilePath) {
        try {
            $savedQueries = Get-Content $FilePath -Raw | ConvertFrom-Json -AsHashtable
            Write-DBLiteLog -Level "Info" -Message "Loaded saved queries from $FilePath"
            return $savedQueries
        }
        catch {
            Write-DBLiteLog -Level "Warning" -Message "Failed to read saved queries: $_"
            return @{}
        }
    }
    else {
        Write-DBLiteLog -Level "Warning" -Message "No saved queries file found at $FilePath. Creating savedqueries.json at this location."
        New-Item -Path $FilePath -ItemType File -Value '{ }' | Out-Null
        Write-DBLiteLog -Level "Info" -Message "Created new saved queries file at $FilePath."
        return @{}
    }
}


<#
.SYNOPSIS
Saves a SQL query to the saved queries JSON file.

.DESCRIPTION
Adds or updates a named SQL query in the savedqueries.json configuration file.
The function retrieves existing saved queries, updates the entry with the provided name,
and writes the updated hashtable back to the file. Logs the save operation.

.PARAMETER Name
The name to associate with the SQL query. This serves as the key in the saved queries file.

.PARAMETER Sql
The SQL query string to save.

.PARAMETER FilePath
Optional path to the saved queries JSON file. Defaults to the standard savedqueries.json in the config folder.

.EXAMPLE
PS> Save-SavedQuery -Name "GetUsers" -Sql "SELECT * FROM Users"
Saves a query named "GetUsers" to the default savedqueries.json file.

.EXAMPLE
PS> Save-SavedQuery -Name "ActiveOrders" -Sql "SELECT * FROM Orders WHERE Status = 'Active'" -FilePath "C:\MyConfig\savedqueries.json"
Saves the query to a custom saved queries file.
#>
function Save-SavedQuery {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Sql,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $FilePath = (Join-Path $PSScriptRoot "..\..\..\config\savedqueries.json")
    )

    $savedQueries = Get-SavedQueries -FilePath $FilePath
    $savedQueries.$Name = $Sql
    $savedQueries | ConvertTo-Json -Depth 1 | Set-Content -Path $FilePath
    Write-DBLiteLog -Level "Info" -Message "Saved query: $Name"
}


<#
.SYNOPSIS
Removes a saved SQL query from the saved queries JSON file.

.DESCRIPTION
Deletes a named query from the savedqueries.json configuration file.
If the specified query exists, it is removed and the updated hashtable is written back to the file.
Logs the removal action. If the query does not exist, no action is taken.

.PARAMETER Name
The name of the saved query to remove.

.PARAMETER FilePath
Optional path to the saved queries JSON file. Defaults to the standard savedqueries.json in the config folder.

.EXAMPLE
PS> Remove-SavedQuery -Name "GetUsers"
Removes the "GetUsers" query from the default savedqueries.json file.

.EXAMPLE
PS> Remove-SavedQuery -Name "OldOrders" -FilePath "C:\MyConfig\savedqueries.json"
Removes the "OldOrders" query from a custom saved queries file.
#>
function Remove-SavedQuery {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [string] $FilePath = (Join-Path $PSScriptRoot "..\..\..\config\savedqueries.json")
    )

    $savedQueries = Get-SavedQueries -FilePath $FilePath
    if ($savedQueries.ContainsKey($Name)) {
        $savedQueries.Remove($Name)
        $savedQueries | ConvertTo-Json -Depth 1 | Set-Content -Path $FilePath
        Write-DBLiteLog -Level "Info" -Message "Removed saved query: $Name"
    }
}


<#
.SYNOPSIS
Populates a ListBox control with saved SQL queries.

.DESCRIPTION
Clears the specified ListBox and loads all saved queries from the savedqueries.json file.
Each query is added as a PSCustomObject with `Name` and `Sql` properties.
The ListBox height is dynamically adjusted based on the number of items.

.PARAMETER ListBox
The System.Windows.Forms.ListBox control to populate with saved queries.

.EXAMPLE
PS> Add-ListBoxSavedQueries -ListBox $QueryListBox
Clears and populates the ListBox control with all saved queries from the default configuration file.
#>
function Add-ListBoxSavedQueries {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.ListBox] $ListBox
    )

    # Clear the listbox
    $ListBox.Items.Clear()
    $savedQueries = Get-SavedQueries

    # Set each listbox entry to hold an object and add them to the listbox
    if ($savedQueries.Count -gt 0) {
        $items = $savedQueries.GetEnumerator() | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Key
                Sql  = $_.Value
            }
        }
        $ListBox.Items.AddRange($items)
    }

    # Dynamically set the height based on the amount of items
    $ListBox.Height = ($ListBox.Items.Count * 20)
}
