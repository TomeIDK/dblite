BeforeAll {
    . "$PSScriptRoot\..\TestBootstrap.ps1"
}

Describe "Export-DbLiteTablesCsv" {

    BeforeEach {
        Mock Write-DBLiteLog {}
        Mock Set-Content {}
        $provider = New-Object PSCustomObject
        $provider | Add-Member -MemberType ScriptMethod -Name GetTableSchema -Value {
            param($table)
            [PSCustomObject]@{
                Columns = @(
                    [PSCustomObject]@{ Name="Id"; DataType="int"; IsPrimaryKey=$true; IsForeignKey=$false; IsUnique=$true },
                    [PSCustomObject]@{ Name="Name"; DataType="varchar"; IsPrimaryKey=$false; IsForeignKey=$false; IsUnique=$false }
                )
            }
        }
        $tables = @("Users", "Products")
        $filePath = "TestDrive:\export.csv"
    }

    It "writes CSV and logs info when schemas are returned" {
        Export-DbLiteTablesCsv -Provider $provider -Tables $tables -FilePath $filePath

        Assert-MockCalled Set-Content -Times 1
        Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter { $Level -eq "Info" -and $Message -like "*exported to $filePath*" }
    }

    It "logs warning and does not write CSV when schema is null" {
        $provider | Add-Member -MemberType ScriptMethod -Name GetTableSchema -Value { return $null } -Force

        Export-DbLiteTablesCsv -Provider $provider -Tables $tables -FilePath $filePath

        Assert-MockCalled Set-Content -Times 0
        Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter { $Level -eq "Warning" -and $Message -like "*Skipping table*" }
    }
}

Describe "Export-DbLiteTablesJson" {

    BeforeEach {
        Mock Write-DBLiteLog {}
        Mock Set-Content {}
        $provider = New-Object PSCustomObject
        $provider | Add-Member -MemberType ScriptMethod -Name GetTableSchema -Value {
            param($table)
            [PSCustomObject]@{
                Name = $table
                Columns = @()
            }
        }
        $tables = @("Users", "Products")
        $filePath = "TestDrive:\export.json"
    }

    It "writes JSON and logs info when schemas are returned" {
        Export-DbLiteTablesJson -Provider $provider -Tables $tables -FilePath $filePath

        Assert-MockCalled Set-Content -Times 1
        Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter { $Level -eq "Info" -and $Message -like "*exported to $filePath*" }
    }

    It "logs warning and does not write JSON when all schemas are null" {
        $provider | Add-Member -MemberType ScriptMethod -Name GetTableSchema -Value { return $null } -Force

        Export-DbLiteTablesJson -Provider $provider -Tables $tables -FilePath $filePath

        Assert-MockCalled Set-Content -Times 0
        Assert-MockCalled Write-DBLiteLog -Times 1 -ParameterFilter { $Level -eq "Warning" -and $Message -like "*No schemas exported*" }
    }
}
