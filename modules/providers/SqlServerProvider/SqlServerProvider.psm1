Import-Module "$PSScriptRoot\..\..\utils\Logger.psm1" -Force

function New-SqlServerProvider {
    $provider = New-DatabaseProviderBase -Name "SQL Server"

    $provider | Add-Member -MemberType ScriptMethod -Name Connect -Value {
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string] $ConnInput
        )

        try {
            $this.Connection = New-Object System.Data.SqlClient.SqlConnection $ConnInput
            $this.Connection.Open()
            $this.IsConnected = $true
            Write-DBLiteLog -Level "Info" -Message "Connected to SQL Server database with connection string: $ConnInput"
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to connect to SQL Server database with connection string $($ConnInput):`n$_"
            throw "SQL Server connection failed: $_"
        }
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
        if ($this.IsConnected -and $this.Connection) {
            $this.Connection.Close()
            $this.IsConnected = $false
            Write-DBLiteLog -Level "Info" -Message "Disconnected from SQL Server database"
        }
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name RunQuery -Value {
        param($query)
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to run query while not connected to the database."
            throw "Not connected to the database."
        }

        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $query
        Write-DBLiteLog -Level "Info" -Message "Executed query: $query"
        return $cmd.ExecuteReader()
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name GetTables -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get tables while not connected to the database."
            throw "Not connected to the database."
        }

        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"

        $reader = $cmd.ExecuteReader()
        Write-DBLiteLog -Level "Info" -Message "Retrieved table list from database."

        $tables = @()

        while ($reader.Read()) {
            $tables += $reader["TABLE_NAME"]
        }

        $reader.Close()

        return $tables
    } -Force

    return $provider
}

Export-ModuleMember -Function New-SqlServerProvider
