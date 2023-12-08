$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d6_input.txt


# Parse the input
$times = $rawData[0].Split(" ").Trim() | Where-Object { $_ -ne "" } | Select-Object -Skip 1
$distances = $rawData[1].Split(" ").Trim() | Where-Object { $_ -ne "" } | Select-Object -Skip 1
$numOfRaces = $times.Count


$myRaces = [System.Collections.ArrayList]::new()
for ($raceIx = 0; $raceIx -lt $numOfRaces; $raceIx++) {
    $raceTime = $times[$raceIx]
    $raceRecord = $distances[$raceIx]


    for ($heat = 0; $heat -le $raceTime; $heat++) {
        $retObj = [pscustomobject]@{
            RaceNum    = $raceIx
            RaceTime   = $raceTime
            RaceRecord = $raceRecord
            HoldTime   = $heat
            Distance   = ""
            Win        = ""
        }
        $retObj.Distance = ($retObj.RaceTime - $retObj.HoldTime) * $retObj.HoldTime
        $retObj.Win = $retObj.Distance -gt $retObj.RaceRecord
        $null = $myRaces.Add($retObj)
    }
}

$wins = $myRaces | Where-Object { $_.Win } | Group-Object RaceNum
$wins

$totalProduct = 1
$wins | ForEach-Object { $totalProduct *= $_.Count }

Write-Host "Total product: $totalProduct"

# Correct answer: 741000
