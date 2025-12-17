
<#
.SYNOPSIS
Retrieves saved SQL queries from a JSON file.

.DESCRIPTION
Loads saved queries from a JSON file, returning an empty hashtable if the file does not exist or cannot be read. Automatically creates the JSON file if missing. Logs operations and errors.

.PARAMETERS
FilePath
    Optional path to the saved queries JSON file. Defaults to config\savedqueries.json.

.RETURNS
Hashtable containing query names as keys and SQL strings as values.
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
Adds or updates a query in the saved queries JSON file under the given name. Logs the operation.

.PARAMETERS
Name
    Name of the query to save.

Sql
    SQL statement associated with the query.

FilePath
    Optional path to the saved queries JSON file. Defaults to config\savedqueries.json.
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
Removes a saved SQL query from the JSON file.

.DESCRIPTION
Deletes the specified query from the saved queries JSON file if it exists. Logs the removal operation.

.PARAMETERS
Name
    Name of the query to remove.

FilePath
    Optional path to the saved queries JSON file. Defaults to config\savedqueries.json.
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
Populates a Windows Forms ListBox with saved queries.

.DESCRIPTION
Clears the provided ListBox and adds all saved queries from the JSON file. Adjusts the ListBox height based on the number of items.

.PARAMETERS
ListBox
    The Windows Forms ListBox control to populate.
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
