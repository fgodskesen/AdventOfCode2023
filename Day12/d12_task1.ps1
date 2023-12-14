$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d12_input.txt
#$rawData = Get-Content $PSScriptRoot\d12_sample.txt

Get-ChildItem $PSScriptRoot\Functions\*.ps1 | ForEach-Object { . $_.FullName }


# '.' is operational
# '#' is damaged
# '?' is unknown
# numbers mean exactly how many broken springs are after each other
# each group of broken springs have at least one OK spring between them



$totalNumberOfArrangements = 0
$x = 0
foreach ($line in $rawData) {
    $x++
    $sprs = $line.Split(" ")[0].Trim()
    $broken = $line.Split(" ")[1].Trim().Split(",")

    $springPermutations = PermutateSprings -BrokenSpringNumbers $broken -FieldLength $sprs.Length

    foreach ($perm in $springPermutations) {
        $isValid = $true
        for ($ix = 0; $ix -lt $perm.Length ; $ix++) {
            $a = $sprs[$ix]
            if ($a -eq '?') {
                # do nothing
            }
            else {
                $b = $perm[$ix]
                if ($a -ne $b) {
                    $isValid = $false
                }
            }
        }
        if ($isValid) {
            $totalNumberOfArrangements++
        }
    }
    #Write-Host "Finished line [$line]"
}

$totalNumberOfArrangements

# final answer 7191