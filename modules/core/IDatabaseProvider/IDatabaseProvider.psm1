Import-Module "$PSScriptRoot\..\..\utils\Logger.psm1" -Force

function New-IDatabaseProvider {
    $provider = [PSCustomObject]@{
        Name        = $null
        Config      = @{}
        IsConnected = $false
        Connection  = $null
    }

    $provider | Add-Member -MemberType ScriptMethod -Name Configure -Value {
        Write-DBLiteLog -Level "Error" -Message "Configure() was called on a provider that has no implementation."
        throw "Configure() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name Connect -Value {
        Write-DBLiteLog -Level "Error" -Message "Connect() was called on a provider that has no implementation."
        throw "Connect() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
        Write-DBLiteLog -Level "Error" -Message "Disconnect() was called on a provider that has no implementation."
        throw "Disconnect() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name RunQuery -Value {
        Write-DBLiteLog -Level "Error" -Message "RunQuery() was called on a provider that has no implementation."
        throw "RunQuery() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetTables -Value {
        Write-DBLiteLog -Level "Error" -Message "GetTables() was called on a provider that has no implementation."
        throw "GetTables() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name NewBackup -Value {
        Write-DBLiteLog -Level "Error" -Message "NewBackup() was called on a provider that has no implementation."
        throw "NewBackup() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetBackupHistory -Value {
        Write-DBLiteLog -Level "Error" -Message "GetBackupHistory() was called on a provider that has no implementation."
        throw "GetBackupHistory() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetLatestBackup -Value {
        Write-DBLiteLog -Level "Error" -Message "GetLatestBackup() was called on a provider that has no implementation."
        throw "GetLatestBackup() not implemented yet"
    }

    return $provider
}

Export-ModuleMember -Function New-IDatabaseProvider
