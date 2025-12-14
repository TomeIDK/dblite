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
            $this.Name = $this.Connection.Database
            $this.IsConnected = $true
            Write-DBLiteLog -Level "Info" -Message "Connected to SQL Server database $($this.Name) with connection string: $ConnInput"
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
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string] $Query
        )
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to run query while not connected to the database."
            throw "Not connected to the database."
        }

        try {
            Write-DBLiteLog -Level "Info" -Message "Executing query: $Query"

            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $Query

            $reader = $cmd.ExecuteReader()
            Write-DBLiteLog -Level "Info" -Message "Query executed successfully."

            $affectedRows = $reader.RecordsAffected
            if ($affectedRows -eq -1) {
                $affectedRows = 0
            }

            Write-QueryLog -Database $this.Name -QueryText $Query -ExecutionStatus "Success" -AffectedRows $affectedRows

            $table = New-Object System.Data.DataTable
            $table.Load($reader)
            $reader.Close()

            return $table
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-DBLiteLog -Level "Error" -Message "Failed to execute query: $errorMessage"
            Write-QueryLog -Database $this.Name -QueryText $Query -ExecutionStatus "Failure"

            return [PSCustomObject]@{
                Error = $errorMessage
            }
        }

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
        Write-QueryLog -Database $this.Name -QueryText $Query -ExecutionStatus "Success"

        $tables = @()

        while ($reader.Read()) {
            $tables += $reader["TABLE_NAME"]
        }

        $reader.Close()

        return $tables
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name NewBackup -Value {
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string] $BackupLocation,

            [Parameter(Mandatory = $true, Position = 1)]
            [ValidateSet("Full", "Differential")] $BackupType,

            [Parameter(Position = 2)]
            [switch] $WithCompression
        )

        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get create backup while not connected to the database."
            throw "Not connected to the database."
        }

        $query = "BACKUP DATABASE [$($this.Name)] TO DISK = N'$($BackupLocation)'"

        if ($BackupType -eq "Differential") {
            $query += " WITH $($BackupType.ToUpper())"
            if ($WithCompression) { $query += ", COMPRESSION" }
        }
        elseif ($BackupType -eq "Full" -and $WithCompression) {
            $query += " WITH COMPRESSION"
        }

        $query += ";"

        try {
            Write-DBLiteLog -Level "Info" -Message "Creating $($BackupType.ToLower()) backup at $($BackupLocation)..."

            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $query
            $cmd.ExecuteNonQuery()

            Write-DBLiteLog -Level "Info" -Message "Backup created successfully."
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Success"
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-DBLiteLog -Level "Error" -Message "Failed to create backup: $errorMessage"
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Failure"
        }
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name GetBackupHistory -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get backup history while not connected to the database."
            throw "Not connected to the database."
        }

        $query = @"
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type AS backup_type,
    bmf.physical_device_name,
    bs.user_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = DB_NAME()
ORDER BY bs.backup_finish_date DESC;
"@

        try {
            Write-DBLiteLog -Level "Info" -Message "Retrieving backup history..."

            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $query
            $reader = $cmd.ExecuteReader()

            Write-DBLiteLog -Level "Info" -Message "Backup history retrieved successfully."

            $table = New-Object System.Data.DataTable
            $table.Load($reader)
            $reader.Close()

            return $table
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve backup history: $errorMessage"
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Failure"

            return [PSCustomObject]@{
                Error = $errorMessage
            }
        }

    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name GetEdition -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get SQL Server edition while not connected to the database."
            throw "Not connected to the database."
        }

        try {
            $query = "SELECT SERVERPROPERTY('Edition')"

            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $query
            Write-DBLiteLog -Level "Info" -Message "SQL Server Edition retrieved successfully."

            return $cmd.ExecuteScalar()
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve SQL Server edition: $($_.Exception.Message)"
        }

    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name GetLatestBackup -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get latest backup while not connected to the database."
            throw "Not connected to the database."
        }

        try {
            $query = @"
SELECT TOP 1 bs.backup_finish_date
FROM msdb.dbo.backupset bs
WHERE bs.database_name = DB_NAME()
ORDER BY bs.backup_finish_date DESC;
"@

            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $query
            Write-DBLiteLog -Level "Info" -Message "Latest backup retrieved successfully."

            return $cmd.ExecuteScalar()
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve latest backup: $($_.Exception.Message)"
        }


    } -Force

    return $provider
}

Export-ModuleMember -Function New-SqlServerProvider
