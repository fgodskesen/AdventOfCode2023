$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d4_input.txt




# Parse the raw data
$cards = [System.Collections.ArrayList]::new()
foreach ($line in $rawData) {
    $id = $line.Substring(4, $line.IndexOf(':') - 4).Trim()
    $parts = $line.SubString($line.IndexOf(':') + 1).Split('|')

    $cardObj = [pscustomobject]@{
        Id                     = $id
        WinningNumbers         = $parts[0].Split(" ").Trim() | Where-Object { $_ -match "\d+" } | Sort-Object | ForEach-Object { [int]$_ }
        HasNumbers             = $parts[1].Split(" ").Trim() | Where-Object { $_ -match "\d+" } | Sort-Object | ForEach-Object { [int]$_ }
        HasWinningNumbers      = @()
        HasWinningNumbersCount = 0
        Points                 = 0
    }

    $cardObj.HasNumbers | ForEach-Object {
        if ($_ -in $cardObj.WinningNumbers) {
            $cardObj.HasWinningNumbers += $_
            $cardObj.HasWinningNumbersCount++
            $cardObj.Points = [Math]::Pow(2, $cardObj.HasWinningNumbersCount - 1)
        }
    }

    $cards += $cardObj
}


Write-Host "Total points"
$cards.Points | Measure-Object -Sum