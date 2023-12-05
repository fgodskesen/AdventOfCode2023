# get all lines in input
$data = Get-Content $PSScriptRoot\d1_input.txt


$totalSum = 0
foreach ($line in $data) {
    #On each line, the calibration value can be found by combining the first digit and the last digit (in that order) to form a single two-digit number.

    $digits = @()
    # Extract Digits into a new array
    for ($x = 0; $x -lt $line.Length; $x++) {

        $restOfLine = $line.Substring($x)

        if ($line[$x] -eq "1") {
            $digits += 1
        }
        elseif ($line[$x] -eq "2") {
            $digits += 2
        }
        elseif ($line[$x] -eq "3") {
            $digits += 3
        }
        elseif ($line[$x] -eq "4") {
            $digits += 4
        }
        elseif ($line[$x] -eq "5") {
            $digits += 5
        }
        elseif ($line[$x] -eq "6") {
            $digits += 6
        }
        elseif ($line[$x] -eq "7") {
            $digits += 7
        }
        elseif ($line[$x] -eq "8") {
            $digits += 8
        }
        elseif ($line[$x] -eq "9") {
            $digits += 9
        }
        elseif ($line[$x] -eq "0") {
            $digits += 0
        }
        elseif ($restOfLine -like "one*") {
            $digits += 1
        }
        elseif ($restOfLine -like "two*") {
            $digits += 2
        }
        elseif ($restOfLine -like "three*") {
            $digits += 3
        }
        elseif ($restOfLine -like "four*") {
            $digits += 4
        }
        elseif ($restOfLine -like "five*") {
            $digits += 5
        }
        elseif ($restOfLine -like "six*") {
            $digits += 6
        }
        elseif ($restOfLine -like "seven*") {
            $digits += 7
        }
        elseif ($restOfLine -like "eight*") {
            $digits += 8
        }
        elseif ($restOfLine -like "nine*") {
            $digits += 9
        }
        elseif ($restOfLine -like "zero*") {
            $digits += 0
        }
    }

    $thisNumber = [int]("{0}{1}" -f $digits[0], $digits[-1])

    "{0}`t`t{1}`t`t{2}" -f $thisNumber, $line, ($digits -join "_")
    $totalSum += $thisNumber
}
Write-Host "Final number : $totalSum"
# final answer: 54504