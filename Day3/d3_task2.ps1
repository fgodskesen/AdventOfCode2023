$ErrorActionPreference = "Stop"

trap {
    Write-Host "Hmm"
}

# Load the input
$rawData = Get-Content $PSScriptRoot\d3_input.txt

$rows = $rawData.Count
$columns = $rawData[0].Length

# Create an empty array with 2 extra rows, i.e. pad the input with a frame of .'s
$dataArray = [array[]]::new($rows + 2)
# fill first and last rows with .s
$dataArray[0] = (1..($columns + 2)) | ForEach-Object { [char]'.' }
$dataArray[$rows + 1] = (1..($columns + 2)) | ForEach-Object { [char]'.' }

# fill middle bits with the input
for ($r = 0; $r -lt $rows; $r++) {
    # join a . at the beginning and end of the string for padding
    $dataArray[$r + 1] = ('.' + $rawData[$r] + '.').ToCharArray()
}

# Prints array
<#
for ($r = 0; $r -lt $dataArray.Count; $r++) {
    Write-Host ($dataArray[$r] -join "")
}
#>



# now... to answer the question... what numbers exist in the array
# that have a symbol in the fields immediately surrounding them....

# first extract all the numbers by looping over the array row by row, left to right.
$numbers = [System.Collections.ArrayList]::new()
for ($r = 0; $r -lt $rows + 2; $r++) {
    for ($c = 0; $c -lt $columns + 2; $c++) {
        if ($dataArray[$r][$c] -match '\d') {
            if ($r -eq 2) { 
                #$true
            }
            $numLength = 1
            $numBeginPos = $c

            while ($dataArray[$r][$numBeginPos + $numLength] -match "\d") {
                $numLength++
            }
            $numString = $dataArray[$r][($numBeginPos)..($numBeginPos + $numLength - 1)] -join ""

            $numObj = [pscustomobject]@{
                Number      = [int]$numString
                ColumnBegin = $numBeginPos
                ColumnEnd   = $numBeginPos + $numLength - 1
                Length      = $numLength
                Row         = $r
            }
            $numbers += $numObj
            # skip ahead some positions so as to not find the same number again as a substring.
            $c += $numLength
        }
    }
}



# Task 2
# The task is to find any occurrence of * that border 2 and exactly 2 numbers. Multiply those numbers and sum all multipla together.

# Lets do that by reusing the numbers array. We scan around each number and find all *s. Each time we find one, we create/update an object that tracks
# which numbers touch that gear


$gears = @{}

# Now look around each number and locate any gears there.
foreach ($num in $numbers) {
    # grab all chars in a frame around the number. Begin at top left corner and work around clockwise

    $coordinatesToScan = @()

    # Row above
    for ($c = $num.ColumnBegin - 1; $c -le $num.ColumnEnd + 1; $c++) {
        $coordinatesToScan += [pscustomobject]@{
            Row = $num.Row - 1
            Col = $c
        }
    }
    # Right
    $coordinatesToScan += [pscustomobject]@{
        Row = $num.Row
        Col = $num.ColumnEnd + 1
    }
    # Row below in reverse
    for ($c = $num.ColumnEnd + 1; $c -ge $num.ColumnBegin - 1; $c--) {
        $coordinatesToScan += [pscustomobject]@{
            Row = $num.Row + 1
            Col = $c
        }
    }
    # Left
    $coordinatesToScan += [pscustomobject]@{
        Row = $num.Row
        Col = $num.ColumnBegin - 1
    }


    foreach ($cell in $coordinatesToScan) {
        if ($dataArray[$cell.Row][$cell.Col] -eq '*') {
            $key = "R{0}#C{1}" -f $cell.Row, $cell.Col
            if (!($gears.ContainsKey($key))) {
                $gears[$key] = [pscustomobject]@{
                    Key         = $key
                    Row         = $cell.Row
                    Col         = $cell.Col
                    Numbers     = @()
                    NumberCount = 0
                }
            }

            $gears[$key].Numbers += $num.Number
            $gears[$key].NumberCount++
        }
    }
}


# on all the gears that have exactly 2 numbers with them, multiply them and add to totalsum
$totalSum = 0
$gears.Values | Where-Object { $_.NumberCount -eq 2 } | ForEach-Object {
    $product = $_.Numbers[0] * $_.Numbers[1]
    $totalSum += $product
}

Write-Host "Final answer: $totalSum"
# 75805607