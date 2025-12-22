BeforeAll {
    . "$PSScriptRoot\..\TestBootstrap.ps1"
}

Describe "Get-QueryHistoryStats" {

    BeforeEach {
        Mock Write-DBLiteLog {}
    }

    Context "When the query history file exists with valid data" {
        BeforeEach {
            Mock Test-Path { $true }
            Mock Get-Content {
@'
[
    { "Database": "db1", "ExecutionStatus": "Success", "ExecutionTime": 100, "Timestamp": "2025-12-22T10:00:00" },
    { "Database": "db1", "ExecutionStatus": "Success", "ExecutionTime": 200, "Timestamp": "2025-12-22T11:00:00" },
    { "Database": "db1", "ExecutionStatus": "Failure", "ExecutionTime": 50, "Timestamp": "2025-12-22T09:00:00" },
    { "Database": "db2", "ExecutionStatus": "Success", "ExecutionTime": 300, "Timestamp": "2025-12-22T12:00:00" }
]
'@
            }
        }

        It "returns correct statistics for the database" {
            $result = Get-QueryHistoryStats -Database "db1"

            $result | Should -Not -BeNull
            $result.QueryCount | Should -Be 2
            $result.AverageExecutionTimeMs | Should -Be 150
            $result.TotalExecutionTimeMs | Should -Be 300
            $result.FastestQueryMs | Should -Be 100
            $result.SlowestQueryMs | Should -Be 200
            $result.LastExecutedQuery | Should -Be "2025-12-22 11:00:00"
        }

        It "does not log anything for successful stats" {
            Get-QueryHistoryStats -Database "db1"
            Assert-MockCalled Write-DBLiteLog -Times 0
        }
    }

    Context "When the query history file exists but no successful queries" {
        BeforeEach {
            Mock Test-Path { $true }
            Mock Get-Content {
@'
[
    { "Database": "db1", "ExecutionStatus": "Failure", "ExecutionTime": 50, "Timestamp": "2025-12-22T09:00:00" }
]
'@
            }
        }

        It "returns null and logs info" {
            $result = Get-QueryHistoryStats -Database "db1"
            $result | Should -BeNull

            Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter {
                $Level -eq "Info" -and $Message -like "*No successful queries*"
            }
        }
    }

    Context "When the query history file is missing" {
        BeforeEach {
            Mock Test-Path { $false }
        }

        It "returns null and logs a warning" {
            $result = Get-QueryHistoryStats -Database "db1"
            $result | Should -BeNull

            Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter {
                $Level -eq "Warning" -and $Message -like "*not found*"
            }
        }
    }

    Context "When the query history file contains invalid JSON" {
        BeforeEach {
            Mock Test-Path { $true }
            Mock Get-Content { "INVALID JSON" }
        }

        It "throws an error and logs it" {
            { Get-QueryHistoryStats -Database "db1" } | Should -Throw

            Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter {
                $Level -eq "Error" -and $Message -like "*Failed to parse*"
            }
        }
    }
}
