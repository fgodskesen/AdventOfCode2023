$ErrorActionPreference = "Stop"

$raw = Get-Content "$PSScriptRoot\d2_input.txt"

$arrGames = [System.Collections.ArrayList]::new()
$arrSubGames = [System.Collections.ArrayList]::new()
foreach ($line in $raw) {
    #sample
    #Game 60: 2 blue, 11 green, 7 red; 5 red, 9 green, 2 blue; 3 blue, 2 red, 8 green; 6 red, 2 blue, 9 green; 5 red, 4 green, 2 blue; 6 red, 5 blue, 11 green
    # only colors are red, green, and blue

    $game = [pscustomobject]@{
        GameID      = ""
        GameName    = ""
        SubGamesRaw = ""
    }
    $game.GameName = $line.Substring(0, $line.IndexOf(':'))
    $game.GameID = [int](($game.GameName -split ' ')[1])


    $game.SubGamesRaw = $line.Substring($line.IndexOf(':') + 1) -split ";" | ForEach-Object { $_.Trim() }


    foreach ($item in $game.SubGamesRaw) {
        $subGame = [pscustomobject]@{
            GameID = $game.GameID
            Raw    = $item
            red    = 0
            green  = 0
            blue   = 0
        }
        $item.Trim().Split(",").Trim() | ForEach-Object {
            $number = [int](($_ -split " ")[0])
            $color = (($_ -split " ")[1])
            $subGame.$color = $number
        }
        $null = $arrSubGames.Add($subGame)
    }
    $null = $arrGames.Add($game)
}


# what is the fewest number of cubes of each color that could have been in the bag to make the game possible?
$arrMinColors = [System.Collections.ArrayList]::new()
foreach ($grp in ($arrSubGames | Group-Object GameId)) {
    $thisGameResult = [pscustomobject]@{
        GameID   = $grp.Name
        MinRed   = $grp.Group.red | Sort-Object -Descending | Select-Object -First 1
        MinGreen = $grp.Group.green | Sort-Object -Descending | Select-Object -First 1
        MinBlue  = $grp.Group.blue | Sort-Object -Descending | Select-Object -First 1
        Product  = 0
    }
    $thisGameResult.Product = $thisGameResult.MinRed * $thisGameResult.MinGreen * $thisGameResult.MinBlue
    $null = $arrMinColors.Add($thisGameResult)
}
$arrMinColors | ConvertTo-Json


# What is the sum of the power of these sets?
$arrMinColors.Product | Measure-Object -Sum 

# final answer is 83435