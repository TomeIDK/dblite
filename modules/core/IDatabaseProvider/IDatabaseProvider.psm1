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

    $provider | Add-Member -MemberType ScriptMethod -Name GetColumns -Value {
        Write-DBLiteLog -Level "Error" -Message "GetColumns() was called on a provider that has no implementation."
        throw "GetColumns() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetRelationships -Value {
        Write-DBLiteLog -Level "Error" -Message "GetRelationships() was called on a provider that has no implementation."
        throw "GetRelationships() not implemented yet"
    }

    return $provider
}

Export-ModuleMember -Function New-IDatabaseProvider
