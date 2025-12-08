function New-IDatabaseProvider {
    $provider = [PSCustomObject]@{
        Name        = $null
        Config      = @{}
        IsConnected = $false
        Connection  = $null
    }

    $provider | Add-Member -MemberType ScriptMethod -Name Configure -Value {
        throw "Configure() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name Connect -Value {
        throw "Connect() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
        throw "Disconnect() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name RunQuery -Value {
        throw "RunQuery() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetTables -Value {
        throw "GetTables() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetColumns -Value {
        throw "GetColumns() not implemented yet"
    }

    $provider | Add-Member -MemberType ScriptMethod -Name GetRelationships -Value {
        throw "GetRelationships() not implemented yet"
    }

    return $provider
}

Export-ModuleMember -Function New-IDatabaseProvider
