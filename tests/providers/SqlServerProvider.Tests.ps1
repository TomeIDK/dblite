BeforeAll {
}

Describe "New-SqlServerProvider" {

    BeforeEach {
        InModuleScope SqlServerProvider {
            Mock Write-DBLiteLog { }
        }
    }

    It "creates a SQL Server provider with expected methods" {
        $provider = New-SqlServerProvider

        $provider | Should -Not -BeNullOrEmpty
        $provider | Should -BeOfType 'PSObject'
        $provider.Name | Should -Be "SQL Server"

        $expectedMethods = @("Connect", "Disconnect", "RunQuery", "GetTables")
        foreach ($method in $expectedMethods) {
            $provider.PSObject.Methods.Name | Should -Contain $method
        }
    }
}
