$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d6_input.txt


# Parse the input
$time = [uint64]($rawData[0].Substring("Time:".Length).Replace(" ", ""))
$dist = [uint64]($rawData[1].Substring("Distance:".Length).Replace(" ", ""))


# Distance travelled = amount of time left multiplied by amount of time waited
# i.e. if I wait 10 secs, then amount of time left is (RaceTime - 10). And distance travelled is (RaceTime - 10)*10
# (RaceTime - HoldTime) * HoldTime
# when is that equal to the race record?

# dist = (time - x) x
# 0 = time x - x^2 - dist
# x^2 - time x + dist = 0

# this is a 2nd degree equation with two solutions
# -b +- SQRT(b^2-4ac)/2a

# a = 1
# b = -time
# c = Record

# lets calculate this with doubles. We can then use rouding up/down as appropriate
$a = [double]1
$b = - [double]$time
$c = [double]$dist

# these can come in any order, i.e., we cannot immediately tell which one is the higher number.
$solutions = @(
    (-$b - [math]::Sqrt(($b * $b) - 4 * $a * $c)) / (2 * $a)
    (-$b + [math]::Sqrt(($b * $b) - 4 * $a * $c)) / (2 * $a)
)

# So we do this to sort that out.
$firstSolution = $solutions | Sort-Object | Select-Object -First 1
$lastSolution = $solutions | Sort-Object | Select-Object -First 1 -Skip 1

# Since the first solution will be the exact value at which the holdtime makes us win the race, and the puzzle only allows integers as holdtime, 
# we must Ceiling this number to get the first winning solution
$firstWin = [uint64]([Math]::Ceiling($firstSolution))

# Similarly, the last winning solution is Floor
$lastWin = [uint64]([Math]::Floor($lastSolution))

# Amount of winning solutions
$lastWin - $firstWin + 1

# 38220708