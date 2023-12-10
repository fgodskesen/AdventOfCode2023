$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d9_input.txt
#$rawData = Get-Content $PSScriptRoot\d9_sample.txt
#$rawData = Get-Content $PSScriptRoot\d9_sample2.txt


$dataSequences = @()
foreach ($line in $rawData) {
    $obj = [pscustomobject]@{
        InputLine = $line
        Lines     = 1
        1         = $line.Split(" ").Trim() | Where-Object { $_ -NE "" } | ForEach-Object { [int]$_ }
    }
    do {
        $done = $true
        $obj.Lines++
        $obj | Add-Member -MemberType NoteProperty -Name $obj.Lines -Value @()
        for ($ix = 1; $ix -lt $obj.$($obj.Lines - 1).Count; $ix++) {
            $obj.$($obj.Lines) += $obj.$($obj.Lines - 1)[$ix] - $obj.$($obj.Lines - 1)[$ix - 1]
        }
        if ($obj.$($obj.Lines) | Where-Object { $_ -ne 0 }) { $done = $false }
    } until ($done)
    $dataSequences += $obj
}

# Now extraprolate
foreach ($obj in $dataSequences) {
    $currentLine = $obj.Lines

    # Add a 0 to last line
    $obj.$currentLine += 0

    while ($currentLine -gt 1) {
        $currentLine--
        $obj.$currentLine += $obj.$currentLine[0] - $obj.$($currentLine + 1)[-1]
    }
    $obj | Add-Member -MemberType NoteProperty -Name "Next" -Value $($obj.1)[-1]
}


$dataSequences | Measure-Object -Sum -Property Next
# correct answer: 900