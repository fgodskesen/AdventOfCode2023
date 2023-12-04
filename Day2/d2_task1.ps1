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
    $null = $arrGames.Add($game)

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
}


#The Elf would first like to know which games would have been possible if the bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?
$maxGameId = $arrGames.GameID | Sort-Object -Descending | select -First 1
$possibleGameIDsSum = 0
for ($x = 1; $x -le $maxGameId; $x++) {
    $isPossible = $true
    foreach ($subGame in ($arrSubGames | Where-Object { $_.GameID -eq $x })) {
        if ($subGame.red -gt 12 -or $subGame.red -lt 0) { $isPossible = $false }
        if ($subGame.green -gt 13 -or $subGame.green -lt 0) { $isPossible = $false }
        if ($subGame.blue -gt 14 -or $subGame.blue -lt 0) { $isPossible = $false }
    }
    if ($isPossible) { $possibleGameIDsSum += $x }
}

# final result
# Determine which games would have been possible if the bag had been loaded with only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum of the IDs of those games?
$possibleGameIDsSum

#result is 2239