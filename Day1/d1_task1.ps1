# get all lines in input
$data = Get-Content $PSScriptRoot\d1_input.txt

$totalSum = 0
foreach ($line in $data) {
    #On each line, the calibration value can be found by combining the first digit and the last digit (in that order) to form a single two-digit number.
    $reverse = $line[-1.. - ($line.Length)] -join ""

    # find first digit in string
    $d1 = [regex]::Match($line, "\d").Value
    $d2 = [regex]::Match($reverse, "\d").Value

    $thisNumber = [int]("{0}{1}" -f $d1, $d2)

    "{0} `t`t {1} `t`t {2}" -f $thisNumber, $line, $reverse
    $totalSum += $thisNumber
}
Write-Host "Final number : $totalSum"
# final answer: 54597