BeforeAll {
    Import-Module "$PSScriptRoot\..\..\modules\utils\Logger\Logger.psm1" -Force
}

Describe "Write-DBLiteLog" {

    InModuleScope Logger {

        BeforeEach {
            Mock Initialize-LogFile { "TestDrive:\logs\dblite$(Get-Date -Format 'ddMMyyyy').log" }
            Mock Format-LogEntry { "[INFO] 2024-01-01 12:00:00: This is a mocked log message." }
            Mock Add-Content { }
        }

        It "calls all helper functions with correct parameters" {
            $logTimestamp = Get-Date ("2024-01-01 12:00:00")

            Write-DBLiteLog -Level "Info" -Timestamp $logTimestamp -Message "This is a mocked log message."

            Assert-MockCalled Initialize-LogFile -Times 1

            Assert-MockCalled -CommandName Format-LogEntry -Times 1 -ParameterFilter {
                $Level -eq "Info" -and
                $Timestamp -eq $logTimestamp -and
                $Message -eq "This is a mocked log message."
            }

            Assert-MockCalled -CommandName Add-Content -Times 1 -ParameterFilter {
                $Path -eq "TestDrive:\logs\dblite$(Get-Date -Format 'ddMMyyyy').log" -and
                $Value -eq "[INFO] 2024-01-01 12:00:00: This is a mocked log message."
            }
        }
    }
}

Describe "Format-LogEntry" {

    It "returns a formatted log entry string" {
        $logMessage = "This is a test log message."
        $logLevel = "Info"
        $logTimestamp = Get-Date ("2024-01-01 12:00:00")

        $result = Format-LogEntry -Level $logLevel -Timestamp $logTimestamp -Message $logMessage

        $expected = "[INFO] 2024-01-01 12:00:00: This is a test log message."
        $result | Should -Be $expected
    }
}

Describe "Initialize-LogFile" {

    It "creates the log folder and today's log file" {
        $basePath = "TestDrive:\logs"

        $result = Initialize-LogFile -BasePath $basePath

        Test-Path $basePath | Should -BeTrue

        $expectedFile = Join-Path $basePath "dblite$(Get-Date -Format 'ddMMyyyy').log"
        $result | Should -Be $expectedFile
        Test-Path $expectedFile | Should -BeTrue
    }

    It "does not recreate today's log file if it already exists" {
        $basePath = "TestDrive:\logs"
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null

        $file = Join-Path $basePath "dblite$(Get-Date -Format 'ddMMyyyy').log"
        New-Item -ItemType File -Path $file -Force | Out-Null

        $beforeWriteTime = (Get-Item $file).LastWriteTime

        Start-Sleep -Milliseconds 50

        Initialize-LogFile -BasePath $basePath | Out-Null

        $afterWriteTime = (Get-Item $file).LastWriteTime

        $afterWriteTime | Should -Be $beforeWriteTime
    }

    It "deletes log files older than 30 days" {
        $basePath = "TestDrive:\logs"
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null

        $oldFile = Join-Path $basePath "dblite01012020.log"
        New-Item -ItemType File -Path $oldFile  -Force | Out-Null
        (Get-Item $oldFile).LastWriteTime = (Get-Date).AddDays(-31)

        Initialize-LogFile -BasePath $basePath | Out-Null

        Test-Path $oldFile | Should -BeFalse
    }
}

Describe "Write-QueryLog" {

    InModuleScope Logger {
        BeforeEach {
            Mock Initialize-QueryHistoryFile { Join-Path $TestDrive 'queryhistory.json' }
            Mock Write-DBLiteLog {}
            $path = Join-Path $TestDrive 'queryhistory.json'
        }

        Context "When history file does not exist" {
            It "creates new history file with one entry" {
                Test-Path $path | Should -BeFalse
                Write-QueryLog -Database 'TestDb' -QueryText "SELECT 1"

                $content = Get-Content $path -Raw | ConvertFrom-Json
                $content.Count | Should -Be 1
                $content[0].Database | Should -Be 'TestDb'
            }
        }

        Context "When history file is empty" {
            It "initializes history when file is empty" {

                "" | Set-Content $path
                Test-Path $path | Should -BeTrue

                Write-QueryLog -Database 'TestDb' -QueryText 'SELECT 1'

                (Get-Content $path -Raw | ConvertFrom-Json).Count | Should -Be 1
            }
        }

        Context "When history file has existing entries" {
            It "appends new entry to existing query history" {
                @(
                    @{ Database = "OldDb"; QueryText = "SELECT 0" }
                ) | ConvertTo-Json | Set-Content $path

                Write-QueryLog -Database "NewDb" -QueryText "SELECT 1"

                $content = Get-Content $path -Raw | ConvertFrom-Json
                $content.Count | Should -Be 2
            }
        }
    }
}

Describe "Initialize-QueryHistoryFile" {
    InModuleScope Logger {
        BeforeEach {
            Mock Write-DBLiteLog {}
            $path = Join-Path $TestDrive 'queryhistory.json'
        }

        Context "When file does not exist" {
            It " creates query history file with empty object" {
                Test-Path $path | Should -BeFalse

                Initialize-QueryHistoryFile -BasePath $path | Should -Be $path

                Test-Path $path | Should -BeTrue
                Get-Content $path -Raw | Should -Be "{}"
            }
        }

        Context "When file already exists" {
            It "does not overwrite existing file" {
                '{"existing":true}' | Set-Content $path
                Initialize-QueryHistoryFile -BasePath $path | Should -Be $path

                (Get-Content $path -Raw).Trim() | Should -Be '{"existing":true}'
            }
        }

        Context "When file creation fails" {
            It "logs error and does not throw" {
                Mock New-Item { throw "disk full" }

                { Initialize-QueryHistoryFile -BasePath $path } | Should -Not -Throw

                Assert-MockCalled Write-DBLiteLog -ParameterFilter {
                    $Level -eq "Error"
                } -Times 1
            }
        }
    }

}

