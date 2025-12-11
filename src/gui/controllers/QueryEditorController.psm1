
function Get-SavedQueries {
    param(
        [Parameter(Mandatory = $false)]
        [string] $FilePath = (Join-Path $PSScriptRoot "..\..\..\config\savedqueries.json")
    )

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

function Save-SavedQuery {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Sql,

        [Parameter(Mandatory = $false, Position = 2)]
        [string] $FilePath = (Join-Path $PSScriptRoot "..\..\..\config\savedqueries.json")
    )

    $savedQueries = Get-SavedQueries
    $savedQueries.$Name = $Sql
    $savedQueries | ConvertTo-Json -Depth 1 | Set-Content -Path $FilePath
    Write-DBLiteLog -Level "Info" -Message "Saved query: $Name"
}

function Remove-SavedQuery {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [string] $FilePath = (Join-Path $PSScriptRoot "..\..\..\config\savedqueries.json")
    )

    $savedQueries = Get-SavedQueries
    if ($savedQueries.ContainsKey($Name)) {
        $savedQueries.Remove($Name)
        $savedQueries | ConvertTo-Json -Depth 1 | Set-Content -Path $FilePath
        Write-DBLiteLog -Level "Info" -Message "Removed saved query: $Name"
    }
}

function Add-ListBoxSavedQueries {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.ListBox] $ListBox
    )

    $ListBox.Items.Clear()
    $savedQueries = Get-SavedQueries

    if ($savedQueries.Count -gt 0) {
        $items = $savedQueries.GetEnumerator() | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Key
                Sql  = $_.Value
            }
        }
        $ListBox.Items.AddRange($items)
    }

    $ListBox.DisplayMember = "Name"
    $ListBox.ValueMember = "Sql"
}

Export-ModuleMember -Function Get-SavedQueries, Save-SavedQuery, Remove-SavedQuery, Add-ListBoxSavedQueries
