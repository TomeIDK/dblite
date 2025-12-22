BeforeAll {
    . "$PSScriptRoot\..\TestBootstrap.ps1"
}


Describe "Get-QueryHistory" {
    BeforeEach {
        Mock Write-DBLiteLog {}
    }

    Context "When the query history file exists with valid data" {
        BeforeEach {
            Mock Initialize-QueryHistoryFile { "TestDrive:\queryhistory.json" }
            Mock Test-Path { $true }

            Mock Get-Content {
                @'
[
  { "Database": "db1", "ExecutionStatus": "Success", "Query": "SELECT 1" },
  { "Database": "db2", "ExecutionStatus": "Failure", "Query": "SELECT 2" },
  { "Database": "db1", "ExecutionStatus": "Failure", "Query": "SELECT 3" }
]
'@
            }
        }

        It "returns only records for the specified database" {
            $result = Get-QueryHistory -Database "db1"

            $result.Count | Should -Be 2
            $result.Database | ForEach-Object { $_ | Should -Be "db1" }
        }

        It "returns empty an array when no records match the database" {
            $result = Get-QueryHistory -Database "nonexistant"

            $result.Count | Should -Be 0
        }
    }

    Context "When the query history file is missing" {
        BeforeEach {
            Mock Initialize-QueryHistoryFile { "TestDrive:\missing.json" }
            Mock Test-Path { $false }
        }

        It "returns empty array" {
            $result = Get-QueryHistory -Database "db1"

            $result.Count | Should -Be 0
        }
    }

    Context "When the query history file contains invalid JSON" {
        BeforeEach {
            Mock Initialize-QueryHistoryFile { "TestDrive:\bad.json" }
            Mock Test-Path { $true }
            Mock Get-Content { "INVALID JSON" }
        }

        It "throws an error" {
            { Get-QueryHistory -Database "db1" } | Should -Throw
        }
    }
}
