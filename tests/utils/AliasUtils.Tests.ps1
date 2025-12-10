BeforeAll {
    Import-Module "$PSScriptRoot\..\..\modules\utils\AliasUtils.psm1" -Force
}

Describe "Resolve-ConnectionString" {

    BeforeEach {
        InModuleScope AliasUtils {
            Mock Write-DBLiteLog { }
        }
    }

    it "resolves an alias" {
        InModuleScope AliasUtils {
            Mock Get-DBLiteAliases { @{"MyDatabase" = "Server=.;Database=TestDB;" } }

            $resolved = Resolve-ConnectionString -InputString "MyDatabase"

            $resolved | Should -Be "Server=.;Database=TestDB;"
        }
    }

    it "returns input if alias not found" {
        InModuleScope AliasUtils {
            Mock Get-DBLiteAliases { @{} }
            $resolved = Resolve-ConnectionString -InputString "Unknown"

            $resolved | Should -Be "Unknown"
        }
    }
}

Describe "Get-DBLiteAliases" {

    BeforeEach {
        InModuleScope AliasUtils {
            Mock Write-DBLiteLog { }
            Mock New-Item {}
        }
        Remove-Item "TestDrive:\config\aliases.json" -ErrorAction SilentlyContinue
    }

    It "creates an alias file if missing and returns empty hashtable" {
        InModuleScope AliasUtils {
            $aliasFile = "TestDrive:\config\aliases.json"

            $result = Get-DBLiteAliases -AliasFileLocation $aliasFile

            $result | Should -BeOfType 'Hashtable'
        }
    }
}
