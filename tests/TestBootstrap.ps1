$src = Join-Path $PSScriptRoot '..\src'

# Core
Get-ChildItem "$src\core" -Filter *.ps1 |
ForEach-Object { . $_ }

# Utils
Get-ChildItem "$src\utils" -Filter *.ps1 |
ForEach-Object { . $_ }

# Providers
Get-ChildItem "$src\providers" -Recurse -Filter *.ps1 |
ForEach-Object { . $_ }

# GUI
Get-ChildItem "$src\gui\controllers" -Recurse -Filter *.ps1 |
ForEach-Object { . $_ }
