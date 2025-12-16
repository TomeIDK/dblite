BeforeAll {
    Import-Module "$PSScriptRoot\..\..\modules\controllers\QueryEditorController\QueryEditorController.psm1" -Force
}

Describe "Get-SavedQueries" {

    InModuleScope QueryEditorController {
        BeforeEach {
            Mock Write-DBLiteLog {}
            $path = Join-Path $TestDrive "savedqueries.json"
        }

        Context "When the saved queries file does not exist" {
            It "creates the saved queries file and returns an empty hashtable" {
                Test-Path $path | Should -BeFalse

                $result = Get-SavedQueries -FilePath $path
                Test-Path $path | Should -BeTrue

                $result.GetType().Name | Should -Be "Hashtable"
                $result.Count | Should -Be 0
            }
        }
    }
}

Describe "Save-SavedQuery" {

    InModuleScope QueryEditorController {
        BeforeEach {
            Mock Write-DBLiteLog {}
            $path = Join-Path $TestDrive "savedqueries.json"
        }

        Context "When a query does not exist yet" {
            It "adds a new query to the saved queries file" {
                "{}" | Set-Content $path

                Save-SavedQuery -Name "TestQuery" -Sql "SELECT 1" -FilePath $path

                $content = Get-Content $path -Raw | ConvertFrom-Json -AsHashtable

                $content.Count | Should -Be 1
                $content.TestQuery | Should -Be "SELECT 1"
            }
        }

        Context "When a query already exists" {
            It "updates the existing query" {
                @{
                    TestQuery = "SELECT 1"
                } | ConvertTo-Json | Set-Content $path

                Save-SavedQuery -Name "TestQuery" -Sql "SELECT 2" -FilePath $path

                $content = Get-Content $path -Raw | ConvertFrom-Json -AsHashtable

                $content.Count | Should -Be 1
                $content.TestQuery | Should -Be "SELECT 2"
            }
        }
    }
}

Describe "Remove-SavedQuery" {
    InModuleScope QueryEditorController {
        BeforeEach {
            Mock Write-DBLiteLog {}
            $path = Join-Path $TestDrive "savedqueries.json"
            Remove-Item $path -ErrorAction SilentlyContinue
        }

        Context "When the query exists" {
            It "removes the existing query" {
                @{
                    Query1 = "SELECT 1"
                    Query2 = "SELECT 2"
                } | ConvertTo-Json | Set-Content $path

                Remove-SavedQuery -Name "Query1" -FilePath $path

                $content = Get-Content $path -Raw | ConvertFrom-Json -AsHashtable

                $content.Count | Should -Be 1
                $content.ContainsKey("Query1") | Should -BeFalse
                $content.Query2 | Should -Be "SELECT 2"
            }
        }

        Context "When the query does not exist" {
            It "does nothing" {
                @{
                    Query1 = "SELECT 1"
                } | ConvertTo-Json | Set-Content $path

                Remove-SavedQuery -Name "MissingQuery" -FilePath $path

                $content = Get-Content $path -Raw | ConvertFrom-Json -AsHashtable

                $content.Count | Should -Be 1
                $content.Query1 | Should -Be "SELECT 1"
            }
        }
    }
}
