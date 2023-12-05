$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d4_input.txt




# Parse the raw data
$originalCards = [System.Collections.ArrayList]::new()
foreach ($line in $rawData) {
    $id = [int]$line.Substring(4, $line.IndexOf(':') - 4).Trim()
    $parts = $line.SubString($line.IndexOf(':') + 1).Split('|')

    $cardObj = [pscustomobject]@{
        Id                     = $id
        WinningNumbers         = $parts[0].Split(" ").Trim() | Where-Object { $_ -match "\d+" } | Sort-Object | ForEach-Object { [int]$_ }
        HasNumbers             = $parts[1].Split(" ").Trim() | Where-Object { $_ -match "\d+" } | Sort-Object | ForEach-Object { [int]$_ }
        HasWinningNumbers      = @()
        HasWinningNumbersCount = 0
        Points                 = 0
        ToDo                   = $true
    }

    $cardObj.HasNumbers | ForEach-Object {
        if ($_ -in $cardObj.WinningNumbers) {
            $cardObj.HasWinningNumbers += $_
            $cardObj.HasWinningNumbersCount++
            $cardObj.Points = [Math]::Pow(2, $cardObj.HasWinningNumbersCount - 1)
        }
    }

    $originalCards += $cardObj
}


# First Attempt... Works badly bc of recursion
<#
$x = 0
while ($cards | Where-Object { $_.ToDo }) {
    $x++
    if ($x % 500 -eq 0) { Write-Host "Total cards: $($cards.Count) - ToDo: $(($cards | Where-Object {$_.ToDo}).Count)" }

    # Pick a random card where ToDo is true
    $thisCard = $cards | Where-Object { $_.ToDo } | Select-Object -First 1

    if ($thisCard.HasWinningNumbersCount -gt 0) {
        # it won. Add more copies of subsequent cards
        $idsToAdd = (([int]$thisCard.Id + 1)..([int]$thisCard.Id + 1 + [int]$thiscard.HasWinningNumbersCount))
        foreach ($id in $idsToAdd) {
            $cards += $originalCards | Select-Object Id, HasWinningNumbersCount, ToDo | Where-Object { [int]$_.Id -eq [int]$id } | ForEach-Object { $_ | ConvertTo-Json | ConvertFrom-Json }
        }
    }
    $thisCard.ToDo = $false
}
#>



# Second attempt. Better. Instead of adding individual cards, we just keep track of how many of each card we have and multiply with that when we add additional cards
$cards = @{}
$originalCards | Sort-Object Id | ForEach-Object { 
    $cards[($_.Id)] = [pscustomobject]@{
        Id        = $_.Id
        CardCount = 1
        WinCount  = $_.HasWinningNumbersCount
    }
}

foreach ($thisKey in ($cards.Keys | Sort-Object)) {
    if ($cards[$thisKey].WinCount) {
        for ($x = $thisKey + 1; $x -le ($thisKey + $cards[$thisKey].WinCount); $x++) {
            if ($cards.ContainsKey($x)) {
                $cards[$x].CardCount += $cards[$thisKey].CardCount
            }
        }
    }
}


#  Including the original set of scratchcards, how many total scratchcards do you end up with?
$cards.Values.CardCount | Measure-Object -Sum

# 8805731