<#
.SYNOPSIS
Creates a SQL Server database provider with full connection, query, and backup capabilities.

.DESCRIPTION
Initializes a database provider object for SQL Server, implementing methods for connecting, disconnecting, running queries, retrieving tables, managing backups, and retrieving SQL Server edition information. All operations are logged using the Logger module, and query executions are logged in the query history.

.METHODS
Connect
    Establishes a connection to a SQL Server database using a connection string. Sets IsConnected to $true on success. Throws an error if connection fails.

Disconnect
    Closes the current SQL Server connection and sets IsConnected to $false.

RunQuery
    Executes a SQL query on the connected database. Returns a DataTable with results on success or a PSCustomObject with an error message on failure. Logs execution success or failure.

GetTables
    Retrieves the list of base tables in the connected database. Returns an array of table names. Throws an error if not connected.

NewBackup
    Creates a database backup at the specified location. Supports "Full" and "Differential" backup types and optional compression. Logs success or failure.

GetBackupHistory
    Retrieves the backup history for the connected database. Returns a DataTable with backup details including start/finish dates, type, file path, and user. Logs failures.

GetEdition
    Returns the SQL Server edition of the connected database instance. Throws an error if not connected.

GetLatestBackup
    Returns the finish date of the most recent backup for the connected database. Throws an error if not connected.

.RETURNS
A PSCustomObject representing a SQL Server database provider with fully implemented methods for connection, query execution, table listing, and backup management.
#>

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
        finally {
            if ($reader) {
                $reader.Close()
            }
        }

    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name GetTables -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get tables while not connected to the database."
            throw "Not connected to the database."
        }

        $query = @"
SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,

    CASE WHEN pk.column_id IS NOT NULL THEN 1 ELSE 0 END AS IsPrimaryKey,
    CASE WHEN fk.parent_column_id IS NOT NULL THEN 1 ELSE 0 END AS IsForeignKey,
    CASE WHEN uq.column_id IS NOT NULL THEN 1 ELSE 0 END AS IsUnique,
    CASE WHEN ix.column_id IS NOT NULL THEN 1 ELSE 0 END AS IsIndexed

FROM sys.tables t
JOIN sys.columns c
    ON t.object_id = c.object_id
JOIN sys.types ty
    ON c.user_type_id = ty.user_type_id

LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON i.object_id = ic.object_id
       AND i.index_id = ic.index_id
    WHERE i.is_primary_key = 1
) pk
    ON c.object_id = pk.object_id
   AND c.column_id = pk.column_id

LEFT JOIN sys.foreign_key_columns fk
    ON c.object_id = fk.parent_object_id
   AND c.column_id = fk.parent_column_id

LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON i.object_id = ic.object_id
       AND i.index_id = ic.index_id
    WHERE i.is_unique = 1
) uq
    ON c.object_id = uq.object_id
   AND c.column_id = uq.column_id

LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON i.object_id = ic.object_id
       AND i.index_id = ic.index_id
    WHERE i.is_primary_key = 0
        AND i.is_unique = 0
) ix
    ON c.object_id = ix.object_id
   AND c.column_id = ix.column_id

ORDER BY t.name, c.column_id;
"@

        $reader = $null
        $tables = @{}

        try {
            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $query

            $reader = $cmd.ExecuteReader()


            while ($reader.Read()) {
                $tableName = $reader['TableName']

                if (-not $tables.ContainsKey($tableName)) {
                    $tables[$tableName] = [PSCustomObject]@{
                        Name    = $tableName
                        Columns = @()
                    }
                }

                $tables[$tableName].Columns += [PSCustomObject]@{
                    Name         = $reader['ColumnName']
                    DataType     = $reader['DataType']
                    IsPrimaryKey = [bool]$reader['IsPrimaryKey']
                    IsForeignKey = [bool]$reader['IsForeignKey']
                    IsUnique     = [bool]$reader['IsUnique']
                    IsIndexed    = [bool]$reader['IsIndexed']
                }
            }

            Write-DBLiteLog -Level "Info" -Message "Retrieved $($tables.Count) tables from database."

            $tables.Values = $tables.Values | Sort-Object Name

            return $tables.Values
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to fetch tables: $($_.Exception.Message)"
            throw
        }
        finally {
            if ($reader) {
                $reader.Close()
            }
        }
    }-Force

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

        # Build the query
        $query = "BACKUP DATABASE [$($this.Name)] TO DISK = N'$($BackupLocation)'"

        if ($BackupType -eq "Differential") {
            $query += " WITH $($BackupType.ToUpper())"
            if ($WithCompression) { $query += ", COMPRESSION" }
        }
        elseif ($BackupType -eq "Full" -and $WithCompression) {
            $query += " WITH COMPRESSION"
        }

        $query += ";"

        # Execute the query
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
        finally {
            if ($reader) {
                $reader.Close()
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

    $provider | Add-Member -MemberType ScriptMethod -Name GetTableSchema -Value {
        param(
            [Parameter(Mandatory = $true)]
            [string] $TableName
        )

        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get table schema while not connected to the database."
            throw "Not connected to the database."
        }

        $query = @"
SELECT
    s.name  AS SchemaName,
    t.name  AS TableName,
    c.name  AS ColumnName,
    ty.name AS DataType,
    c.is_nullable AS IsNullable,

    CASE WHEN pk.column_id IS NOT NULL THEN 1 ELSE 0 END AS IsPrimaryKey,
    CASE WHEN fk.parent_column_id IS NOT NULL THEN 1 ELSE 0 END AS IsForeignKey,
    CASE WHEN uq.column_id IS NOT NULL THEN 1 ELSE 0 END AS IsUnique
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id

LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON i.object_id = ic.object_id
       AND i.index_id = ic.index_id
    WHERE i.is_primary_key = 1
) pk ON pk.object_id = c.object_id AND pk.column_id = c.column_id

LEFT JOIN (
    SELECT parent_object_id, parent_column_id
    FROM sys.foreign_key_columns
) fk ON fk.parent_object_id = c.object_id AND fk.parent_column_id = c.column_id

LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON i.object_id = ic.object_id
       AND i.index_id = ic.index_id
    WHERE i.is_unique = 1 AND i.is_primary_key = 0
) uq ON uq.object_id = c.object_id AND uq.column_id = c.column_id

WHERE t.name = '$TableName'
ORDER BY c.column_id;

"@
        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $query
        $reader = $null

        try {
            $reader = $cmd.ExecuteReader()
            $results = @()

            while ($reader.Read()) {
                $row = @{}
                for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                    $row[$reader.GetName($i)] = $reader.GetValue($i)
                }
                $results += [PSCustomObject]$row
            }

            if (-not $results) {
                Write-DBLiteLog -Level "Warning" -Message "No schema found for table $TableName."
                return $null
            }

            $first = $results[0]

            Write-DBLiteLog -Level "Info" -Message "Table schema for $TableName retrieved successfully."

            return [PSCustomObject]@{
                TableName = $first.TableName
                Schema    = $first.SchemaName
                Columns   = foreach ($row in $results) {
                    [PSCustomObject]@{
                        Name         = $row.ColumnName
                        DataType     = $row.DataType
                        IsNullable   = [bool]$row.IsNullable
                        IsPrimaryKey = [bool]$row.IsPrimaryKey
                        IsForeignKey = [bool]$row.IsForeignKey
                        IsUnique     = [bool]$row.IsUnique
                    }
                }
            }
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve table schema for $($TableName): $($_.Exception.Message)"
            throw
        }
        finally {
            if ($reader) {
                $reader.Close()
            }
            if ($cmd) {
                $cmd.Dispose()
            }
        }
    } -Force

    return $provider
}
