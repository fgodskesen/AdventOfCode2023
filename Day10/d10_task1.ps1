$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d10_input.txt
#$rawData = Get-Content $PSScriptRoot\d10_sample1.txt
#$rawData = Get-Content $PSScriptRoot\d10_sample2.txt
#$rawData = Get-Content $PSScriptRoot\d10_sample3.txt


# We assume fully rectangular input, i.e. all rows same width
$rows = $rawData.Count
$cols = $rawData[0].Length


<#
| is a vertical pipe connecting north and south.
- is a horizontal pipe connecting east and west.
L is a 90-degree bend connecting north and east.
J is a 90-degree bend connecting north and west.
7 is a 90-degree bend connecting south and west.
F is a 90-degree bend connecting south and east.
. is ground; there is no pipe in this tile.
S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.
#>

$pipeSegments = @{}
# Locate coordinates for S
for ($r = 0; $r -lt $rows; $r++) {
    for ($c = 0; $c -lt $cols; $c++) {
        $obj = [pscustomobject]@{
            Id         = "$r#$c"
            Row        = $r
            Col        = $c
            Symbol     = $rawData[$r][$c]
            ConnectsTo = @() + $(
                switch ($rawData[$r][$c]) {
                    '|' { "$($r-1)#$($c+0)", "$($r+1)#$($c+0)"; break }
                    '-' { "$($r+0)#$($c-1)", "$($r+0)#$($c+1)"; break }
                    'L' { "$($r-1)#$($c+0)", "$($r+0)#$($c+1)"; break }
                    'J' { "$($r-1)#$($c+0)", "$($r+0)#$($c-1)"; break }
                    '7' { "$($r+1)#$($c+0)", "$($r+0)#$($c-1)"; break }
                    'F' { "$($r+1)#$($c+0)", "$($r+0)#$($c+1)"; break }
                    '.' { break }
                    default { break }
                }
            )
            Distance   = -1
            Next       = $null
            NextId     = ""
            Previous   = $null
            PreviousId = ""
        }
        $null = $pipeSegments.Add($obj.Id, $obj)
    }
}

# Link nodes

Write-Host "Calculating..."
$startingPoint = $pipeSegments.Values | Where-Object { $_.Symbol -eq 'S' }
$startingPoint.Distance = 0
$startingPoint.ConnectsTo = $pipeSegments.Values | Where-Object { $_.ConnectsTo -eq $startingPoint.Id } | Select-Object -ExpandProperty Id
$startingPoint.NextId = $startingPoint.ConnectsTo[0]
$startingPoint.Next = $pipeSegments[$startingPoint.NextId]
$startingPoint.PreviousId = $startingPoint.ConnectsTo[1]
$startingPoint.Previous = $pipeSegments[$startingPoint.PreviousId]

$currentNode = $startingPoint
do {
    Clear-Variable previousNode -ErrorAction SilentlyContinue
    $previousNode = $currentNode
    Clear-Variable currentNode -ErrorAction SilentlyContinue
    $currentNode = $previousNode.Next
    $currentNode.PreviousId = $previousNode.Id
    $currentNode.Previous = $previousNode
    $currentNode.NextId = $currentNode.ConnectsTo | Where-Object { $_ -ne $previousNode.Id }
    $currentNode.Next = $pipeSegments[$currentNode.NextId]
    $currentNode.Distance = $previousNode.Distance + 1
} until ($currentNode.Id -eq $startingPoint.Id)


$maxDistance = $pipeSegments.Values | Sort-Object Distance | Select-Object -Last 1 -ExpandProperty Distance
Write-Host "Maximum distance travelled from S"
[Math]::Ceiling($maxDistance / 2)

# 6738