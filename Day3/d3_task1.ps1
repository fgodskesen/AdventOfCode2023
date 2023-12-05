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

# Now look around each number and make sure there is a "symbol" somewhere around it.
# i.e. something that is neither a . nor a digit
foreach ($num in $numbers) {
    $num | Add-Member -MemberType NoteProperty -Name "IsValid" -Value $false -Force
    # grab all chars in a frame around the number.
    $frameChars = $dataArray[$num.Row - 1][($num.ColumnBegin - 1)..($num.ColumnEnd + 1)] + `
        $dataArray[$num.Row + 1][($num.ColumnBegin - 1)..($num.ColumnEnd + 1)] + `
        $dataArray[$num.Row][$num.ColumnBegin - 1] + `
        $dataArray[$num.Row][$num.ColumnEnd + 1]
    $num | Add-Member -MemberType NoteProperty -Name "FrameChars" -Value ($frameChars -join "") -Force
    if ($frameChars -match "[^0-9\.]") { $num.IsValid = $true }
}


# What is the sum of all of the part numbers in the engine schematic?
# I.e. sum of all numbers that are "Valid"
$numbers | Where-Object { $_.IsValid } | Select-Object -ExpandProperty Number | Measure-Object -Sum

# final result, 525911