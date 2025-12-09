# Resolve project root
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Load all modules automatically
Get-ChildItem "$ProjectRoot\modules" -Recurse -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName -Force
}
