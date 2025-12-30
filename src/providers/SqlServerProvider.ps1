<#
.SYNOPSIS
Creates a SQL Server provider object for DBLite with methods for managing databases, queries, backups, and metadata.

.DESCRIPTION
Initializes a SQL Server provider object that allows connecting to a database, running queries, fetching table schemas and indexes, performing backups, and retrieving performance stats and users. Designed for use with DBLite's logging and query tracking system. Each method logs actions and errors. Side effects include opening and closing database connections. Returns a PSCustomObject with multiple methods representing provider operations.

.PARAMETER None
This function takes no parameters. All configuration is handled via methods on the returned provider object.

.EXAMPLE
PS> $provider = New-SqlServerProvider
Initializes a new SQL Server provider object. You can then connect using:
$provider.Connect("Server=.;Database=MyDB;User Id=sa;Password=secret;")

.EXAMPLE
PS> $provider.Connect("Server=.;Database=MyDB;Integrated Security=True;")
Connects to the SQL Server database using Windows authentication. Logs success or failure and sets connection state.

.EXAMPLE
PS> $tables = $provider.GetTables()
Retrieves all tables and columns with metadata including primary keys, foreign keys, uniqueness, and indexing.

.EXAMPLE
PS> $provider.NewBackup("C:\Backups\MyDB.bak", "Full", $true)
Creates a full compressed backup of the current database to the specified location.

.OUTPUTS
PSCustomObject representing the SQL Server provider with methods:
- Connect, Disconnect, RunQuery, GetTables, GetTableSchema, NewBackup, GetBackupHistory,
  GetLatestBackup, GetEdition, GetIndexes, GetPerformanceStats, GetUsers.
#>
function New-SqlServerProvider {
    $provider = New-DatabaseProviderBase -Name "SQL Server"

    # Dependency validation
    try {
        [void][System.Data.SqlClient.SqlConnection]
    }
    catch {
        Write-DBLiteLog -Level "Error" -Message "System.Data.SqlClient not available on this system."
        throw "System.Data.SqlClient not available. Use Windows PowerShell 5.1 or install Microsoft.Data.SqlClient."
    }


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
            Write-DBLiteLog -Level "Info" -Message "Connected to SQL Server database $($this.Name)"
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to connect to SQL Server database:`n$_"
            throw "SQL Server connection failed: $_"
        }
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
        if ($this.IsConnected -and $this.Connection) {
            $this.Connection.Close()
            $this.IsConnected = $false
            Write-DBLiteLog -Level "Info" -Message "Disconnected from $($provider.Name) database"
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

            $start = Get-Date
            $reader = $cmd.ExecuteReader()
            $end = Get-Date
            $executionTime = ($end - $start).TotalMilliseconds

            Write-DBLiteLog -Level "Info" -Message "Query executed successfully."

            $affectedRows = $reader.RecordsAffected
            if ($affectedRows -eq -1) {
                $affectedRows = 0
            }

            Write-QueryLog -Database $this.Name -QueryText $Query -ExecutionStatus "Success" -AffectedRows $affectedRows -ExecutionTime $executionTime

            $table = New-Object System.Data.DataTable
            $table.Load($reader)

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
            if ($cmd) {
                $cmd.Dispose()
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

            return $tables.Values | Sort-Object -Property Name
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to fetch tables: $($_.Exception.Message)"
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
            throw
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
            if ($cmd) {
                $cmd.Dispose()
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
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Failure"
            throw
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
            $result = $cmd.ExecuteScalar()

            if ($null -eq $result) {
                return "None"
            }
            else {
                return $result.ToString("dd/MM/yyyy HH:mm:ss")
            }
        }
        catch {
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve latest backup: $($_.Exception.Message)"
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Failure"
            return "Failed to retrieve latest backup (see logs)"
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
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Failure"
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


    $provider | Add-Member -MemberType ScriptMethod -Name GetIndexes -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get indexes while not connected to the database."
            throw "Not connected to the database."
        }

        $query = @"
WITH IndexSizes AS (
    SELECT
        ps.object_id,
        ps.index_id,
        SUM(ps.used_page_count) * 8 AS SizeKB
    FROM sys.dm_db_partition_stats ps
    GROUP BY ps.object_id, ps.index_id
),
IndexUsage AS (
    SELECT
        ius.object_id,
        ius.index_id,
        (
            SELECT MAX(v)
            FROM (VALUES
                (ius.last_user_seek),
                (ius.last_user_scan),
                (ius.last_user_lookup)
            ) AS value(v)
        ) AS LastUsedSinceRestart
    FROM sys.dm_db_index_usage_stats ius
    WHERE ius.database_id = DB_ID()
)
SELECT
    QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS TableName,
    i.name AS IndexName,
    STRING_AGG(
        c.name + CASE ic.is_descending_key WHEN 1 THEN ' DESC' ELSE ' ASC' END,
        ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexedColumns,
    CASE
        WHEN i.is_primary_key = 1 THEN 'Primary Key'
        WHEN i.is_unique = 1 AND i.type_desc LIKE '%CLUSTERED%' THEN 'Unique Clustered'
        WHEN i.is_unique = 1 THEN 'Unique Nonclustered'
        ELSE i.type_desc
    END AS IndexType,
    ISNULL(sz.SizeKB, 0) AS SizeKB,
    us.LastUsedSinceRestart
FROM sys.indexes i
JOIN sys.tables t
    ON i.object_id = t.object_id
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
JOIN sys.columns c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
LEFT JOIN IndexSizes sz
    ON i.object_id = sz.object_id
    AND i.index_id = sz.index_id
LEFT JOIN IndexUsage us
    ON i.object_id = us.object_id
    AND i.index_id = us.index_id
WHERE
    i.type > 0                 -- excludes heaps
    AND ic.is_included_column = 0
GROUP BY
    s.name,
    t.name,
    i.name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    sz.SizeKB,
    us.LastUsedSinceRestart
ORDER BY
    TableName,
    IndexName;
"@

        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $query
        $reader = $null

        try {
            Write-DBLiteLog -Level "Info" -Message "Retrieving indexes..."

            $reader = $cmd.ExecuteReader()


            $table = New-Object System.Data.DataTable
            $table.Load($reader)

            Write-DBLiteLog -Level "Info" -Message "Retrieved $($table.Rows.Count) indexes."

            return $table
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve indexes: $errorMessage"
            Write-QueryLog -Database $this.Name -QueryText $query -ExecutionStatus "Failure"

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


    $provider | Add-Member -MemberType ScriptMethod -Name GetPerformanceStats -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get performance stats while not connected to the database."
            throw "Not connected to the database."
        }

        $queriesPerSecondQuery = @"
SELECT
    cntr_value AS batch_requests_per_sec
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%SQL Statistics%'
  AND counter_name = 'Batch Requests/sec';
"@

        $connectionsQuery = @"
SELECT COUNT(*) AS total_connections
FROM sys.dm_exec_connections;
"@

        $cpuUsageQuery = @"
WITH cpu AS (
    SELECT
        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS sql_cpu,
        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS system_idle
    FROM (
        SELECT CONVERT(xml, record) AS record
        FROM sys.dm_os_ring_buffers
        WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
          AND record LIKE '%<SystemHealth>%'
    ) AS rb
)
SELECT TOP 1
    sql_cpu AS sql_cpu_percent,
    100 - system_idle - sql_cpu AS other_process_cpu_percent
FROM cpu
ORDER BY sql_cpu DESC;
"@

        $memoryUsageQuery = @"
SELECT
    physical_memory_in_use_kb / 1024 AS memory_used_mb
FROM sys.dm_os_process_memory;
"@

        function Invoke-QueryInternal {
            param(
                [string] $Query
            )

            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $Query
            $reader = $null

            try {
                $reader = $cmd.ExecuteReader()
                $table = New-Object System.Data.DataTable
                $table.Load($reader)
                return $table
            }
            finally {
                if ($reader) {
                    $reader.Close()
                }
                if ($cmd) {
                    $cmd.Dispose()
                }
            }
        }

        Write-DBLiteLog -Level "Info" -Message "Retrieving performance statistics..."

        try {

            $qpsRow = Invoke-QueryInternal $queriesPerSecondQuery | Select-Object -First 1
            $connRow = Invoke-QueryInternal $connectionsQuery | Select-Object -First 1
            $cpuRow = Invoke-QueryInternal $cpuUsageQuery | Select-Object -First 1
            $memoryRow = Invoke-QueryInternal $memoryUsageQuery | Select-Object -First 1

            Write-DBLiteLog -Level "Info" -Message "Retrieved performance statistics successfully."

            return [PSCustomObject]@{
                Timestamp = Get-Date
                Database  = $this.Name
                Load      = @{
                    QueriesPerSecond = [int]$qpsRow.batch_requests_per_sec
                    Connections      = [int]$connRow.total_connections
                }
                Cpu       = @{
                    SqlServerPercent = [int]$cpuRow.sql_cpu_percent
                }
                Memory    = @{
                    UsedMB = [int]$memoryRow.memory_used_mb
                }
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve performance statistics: $errorMessage"
            throw
        }
    } -Force

    $provider | Add-Member -MemberType ScriptMethod -Name GetUsers -Value {
        if (-not $this.IsConnected) {
            Write-DBLiteLog -Level "Error" -Message "Attempted to get users while not connected to the database."
            throw "Not connected to the database."
        }

        $query = @"
SELECT
    name AS Username,
    type_desc AS Type,
    is_disabled AS IsDisabled,
    create_date AS CreatedOn,
    modify_date AS ModifiedOn
FROM sys.sql_logins
"@

        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $query
        $reader = $null

        try {
            $reader = $cmd.ExecuteReader()
            $table = New-Object System.Data.DataTable
            $table.Load($reader)
            return $table
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-DBLiteLog -Level "Error" -Message "Failed to retrieve users: $errorMessage"
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
