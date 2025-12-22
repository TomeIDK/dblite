BeforeAll {
    . "$PSScriptRoot\..\TestBootstrap.ps1"
}

Describe "Resolve-ConnectionString" {

    BeforeEach {
        Mock Write-DBLiteLog { }
    }

    it "resolves an alias" {
        Mock Get-DBLiteAliases { @{"MyDatabase" = "Server=.;Database=TestDB;" } }

        $resolved = Resolve-ConnectionString -InputString "MyDatabase"

        $resolved | Should -Be "Server=.;Database=TestDB;"
    }

    it "returns input if alias not found" {
        Mock Get-DBLiteAliases { @{} }
        $resolved = Resolve-ConnectionString -InputString "Unknown"

        $resolved | Should -Be "Unknown"
    }
}

Describe "Get-DBLiteAliases" {

    BeforeEach {
        Mock Write-DBLiteLog { }
        Mock New-Item {}
        Remove-Item "TestDrive:\config\aliases.json" -ErrorAction SilentlyContinue
    }

    It "creates an alias file if missing and returns empty hashtable" {
        $aliasFile = "TestDrive:\config\aliases.json"

        $result = Get-DBLiteAliases -AliasFileLocation $aliasFile

        $result | Should -BeOfType 'Hashtable'
    }
}
