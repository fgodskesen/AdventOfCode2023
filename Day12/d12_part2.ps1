$ErrorActionPreference = "Stop"
#$rawData = Get-Content $PSScriptRoot\d12_input.txt
$rawData = Get-Content $PSScriptRoot\d12_sample.txt

Get-ChildItem $PSScriptRoot\Functions\*.ps1 | ForEach-Object { . $_.FullName }


# '.' is operational
# '#' is damaged
# '?' is unknown
# numbers mean exactly how many broken springs are after each other
# each group of broken springs have at least one OK spring between them



$totalNumberOfArrangements = 0
$x = 0

$rawData = $rawData[0]
foreach ($line in $rawData) {
    $x++
    $sprs = ($line.Split(" ")[0].Trim()) * 5
    $broken = ($line.Split(" ")[1].Trim().Split(",")) * 5

    # need to rewrite to use combinatorics instead. 
    # No way we can generate this many strings and actually compare them
}

$totalNumberOfArrangements

# final answer 7191