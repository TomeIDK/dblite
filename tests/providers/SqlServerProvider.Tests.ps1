BeforeAll {
    Import-Module "$PSScriptRoot\..\..\modules\core\DatabaseProviderBase\DatabaseProviderBase.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\modules\core\IDatabaseProvider\IDatabaseProvider.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\modules\providers\SqlServerProvider\SqlServerProvider.psm1" -Force
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
