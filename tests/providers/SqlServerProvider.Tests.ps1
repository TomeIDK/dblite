BeforeAll {
    . "$PSScriptRoot\..\TestBootstrap.ps1"
}

Describe "New-SqlServerProvider" {

    BeforeEach {
        Mock Write-DBLiteLog { }
    }

    It "creates a SQL Server provider with expected methods" {
        $provider = New-SqlServerProvider

        $provider | Should -Not -BeNullOrEmpty
        $provider | Should -BeOfType 'PSObject'
        $provider.Name | Should -Be "SQL Server"

        $expectedMethods = @("Connect", "Disconnect", "RunQuery", "GetTables", "NewBackup", "GetBackupHistory", "GetEdition", "GetLatestBackup", "GetTableSchema", "GetIndexes", "GetPerformanceStats", "GetUsers")
        foreach ($method in $expectedMethods) {
            $provider.PSObject.Methods.Name | Should -Contain $method
        }
    }
}
