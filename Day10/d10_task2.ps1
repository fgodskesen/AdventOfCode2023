$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d10_sample5.txt
# should have 4 enclosed tiles

#$rawData = Get-Content $PSScriptRoot\d10_sample7.txt
# should have 10 enclosed tiles

$rawData = Get-Content $PSScriptRoot\d10_input.txt

$inputArray = @()
$inputArray += ((0..$($rawData[0].Length + 3)) | ForEach-Object { "." }) -join ""
$inputArray += $rawData | ForEach-Object { "..$($_).." }
$inputArray += ((0..$($rawData[0].Length + 3)) | ForEach-Object { "." }) -join ""

$rows = $inputArray.Count
$cols = $inputArray[0].Length


class Cell {
    hidden $_Id = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Id' -Value {
            "$($this.Row)#$($this.Col)" 
        } -SecondValue { 
            throw "Parameter ID is ReadOnly" 
        }
    )
    [int]$Row
    [int]$Col
    #[char]$Symbol

    [Cell]$NextOnLoop
    [Cell]$PreviousOnLoop

    [int]$Distance = 0
    [bool]$IsLoop = $false
    [bool]$IsStart = $false
    [bool]$IsEdge = $false
    [bool]$IsEnclosed = $false

    [bool]$IsInsideNW
    [bool]$IsInsideNE
    [bool]$IsInsideSW
    [bool]$IsInsideSE

    [char]$DirectionOfMovement

    hidden $_PipeConnectsTo = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'PipeConnectsTo' -Value {
            $this._PipeConnectsTo
        } -SecondValue { 
            throw "Parameter ID is ReadOnly" 
        }
    )

    hidden $_Symbol2 = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Symbol2' -Value {
            $this._Symbol2
        } -SecondValue {
            throw "Parameter is ReadOnly" 
        }
    )

    hidden $_Symbol = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Symbol' -Value {
            $this._Symbol
        } -SecondValue {
            param ($arg)
            $this._Symbol = $arg
            $this._Symbol2 = switch ($this.Symbol) {
                '|' { [char]0x2551; break }
                '-' { [char]0x2550; break }
                'L' { [char]0x255a; break }
                'J' { [char]0x255d; break }
                '7' { [char]0x2557; break }
                'F' { [char]0x2554; break }
                '.' { "."; break }
                'S' { "S"; break }
                default { break }
            }
        }
    )

    Cell ($_Row, $_Col, $_Symbol) {
        $this.Row = $_Row
        $this.Col = $_Col
        $this.Symbol = $_Symbol

        $this._PipeConnectsTo = @() + $(
            switch ($_Symbol) {
                '|' { "$($_Row-1)#$($_Col+0)", "$($_Row+1)#$($_Col+0)"; break }
                '-' { "$($_Row+0)#$($_Col-1)", "$($_Row+0)#$($_Col+1)"; break }
                'L' { "$($_Row-1)#$($_Col+0)", "$($_Row+0)#$($_Col+1)"; break }
                'J' { "$($_Row-1)#$($_Col+0)", "$($_Row+0)#$($_Col-1)"; break }
                '7' { "$($_Row+1)#$($_Col+0)", "$($_Row+0)#$($_Col-1)"; break }
                'F' { "$($_Row+1)#$($_Col+0)", "$($_Row+0)#$($_Col+1)"; break }
                '.' { break }
                'S' { $this.IsStart = $true; break }
                default { break }
            }
        )
    }
}



# Create Cell objects from all fields in inputArray
$allCells = @{}
for ($r = 0; $r -lt $rows; $r++) {
    for ($c = 0; $c -lt $cols; $c++) {
        $obj = [Cell]::new($r, $c, $inputArray[$r][$c])
        $allCells[$obj.Id] = $obj
    }
}






# Calculate position and go around on the main loop
$startingPoint = $allCells.Values | Where-Object { $_.Symbol -eq 'S' }

$startingPoint.Distance = 0

# Access hidden property to override the getter on the class
$startingPoint._PipeConnectsTo = $allCells.Values | Where-Object { $_.PipeConnectsTo -eq $startingPoint.Id } | Select-Object -ExpandProperty Id
$startingPoint.NextOnLoop = $allCells[$startingPoint.PipeConnectsTo[0]]
$startingPoint.PreviousOnLoop = $allCells[$startingPoint.PipeConnectsTo[1]]
$startingPoint.IsStart = $true




# Replace starting symbol with something more fitting
if ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row)#$($startingPoint.Col -1)") {
    if ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row - 1)#$($startingPoint.Col)") {
        # WN
        $startingPoint.Symbol = "J"
    }
    elseif ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row)#$($startingPoint.Col + 1)") {
        # WE
        $startingPoint.Symbol = "-"
    }
    elseif ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row + 1)#$($startingPoint.Col)") {
        # WS
        $startingPoint.Symbol = "7"
    }
}
elseif ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row - 1)#$($startingPoint.Col)") {
    if ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row)#$($startingPoint.Col + 1)") {
        # NE
        $startingPoint.Symbol = "L"
    }
    elseif ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row + 1)#$($startingPoint.Col)") {
        # NS
        $startingPoint.Symbol = "|"
    }
}
elseif ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row)#$($startingPoint.Col + 1)") {
    if ($startingPoint.PipeConnectsTo -contains "$($startingPoint.Row + 1)#$($startingPoint.Col)") {
        # ES
        $startingPoint.Symbol = "F"
    }
}
else {
    $startingPoint.Symbol = "X"
}




$currentNode = $startingPoint
do {
    Clear-Variable previousNode -ErrorAction SilentlyContinue
    $previousNode = $currentNode
    Clear-Variable currentNode -ErrorAction SilentlyContinue
    $currentNode = $previousNode.NextOnLoop
    $currentNode.PreviousOnLoop = $previousNode
    $currentNode.NextOnLoop = $allCells[($currentNode.PipeConnectsTo | Where-Object { $_ -ne $currentNode.PreviousOnLoop.Id })]

    $currentNode.DirectionOfMovement = $(
        if ($currentNode.NextOnLoop.Row -gt $currentNode.Row) {
            "S"
        }
        elseif ($currentNode.NextOnLoop.Row -lt $currentNode.Row) {
            "N"
        }
        elseif ($currentNode.NextOnLoop.Col -gt $currentNode.Col) {
            "E"
        }
        elseif ($currentNode.NextOnLoop.Col -lt $currentNode.Col) {
            "W"
        }
    )

    $currentNode.Distance = $previousNode.Distance + 1
    $currentNode.IsLoop = $true
} until ($currentNode.Id -eq $startingPoint.Id)


# Replace all "non loop symbols"
$allCells.Values | ForEach-Object {
    if (!$_.IsLoop) {
        $_.Symbol = '.'
    }
}

function PrintCells ($Cells, $rows, $cols) {
    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            Write-Host $Cells["$r#$c"].Symbol -NoNewline
        }
        Write-Host ""
    }
}

function PrintCells2 ([ref]$Cells, $rows, $cols) {
    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            if ($Cells.Value["$r#$c"].IsStart) {
                $fc = @{ForeGroundColor = "Yellow" }
            }
            elseif ($Cells.Value["$r#$c"].IsLoop) {
                $fc = @{ForeGroundColor = "Gray" }
            }
            elseif ($Cells.Value["$r#$c"].IsEdge) {
                $fc = @{ForeGroundColor = "Green" }
            }
            elseif ($Cells.Value["$r#$c"].IsEnclosed) {
                $fc = @{ForeGroundColor = "Red" }
            }
            else {
                $fc = @{ForeGroundColor = "White" }
            }
            Write-Host $Cells.Value["$r#$c"].Symbol2 -NoNewline @fc
        }
        Write-Host ""
    }
}





# Cast a ray from outside in towards starting point. We must hit the loop eventually
$startingPoint = $allCells.Values | Where-Object { $_.IsStart }

# Cast a ray from outside in towards starting point. We must hit the loop eventually
for ($c = 0; $c -le $startingPoint.Row; $c++) {
    $thisCell = $allCells["$($startingPoint.Row)#$c"]
    if ($thisCell.IsLoop) {
        switch ($thisCell.Symbol) {
            '|' {
                $thisCell.IsInsideNW = $false
                $thisCell.IsInsideNE = $true
                $thisCell.IsInsideSW = $false
                $thisCell.IsInsideSE = $true
                break
            }
            'L' {
                $thisCell.IsInsideNW = $false
                $thisCell.IsInsideNE = $true
                $thisCell.IsInsideSW = $false
                $thisCell.IsInsideSE = $false
                break
            }
            'F' {
                $thisCell.IsInsideNW = $false
                $thisCell.IsInsideNE = $false
                $thisCell.IsInsideSW = $false
                $thisCell.IsInsideSE = $true
                break
            }
            default { throw "this should not be possible. loose corner?"; break }
        }
        break
    }
}


# Now traverse the figure in forward direction until all cells have been touched and the 4 corners set to inside or not
$loopStartingPoint = $thisCell.Id
$currentNode = $allCells[$loopStartingPoint]
do {
    Clear-Variable previousNode -ErrorAction SilentlyContinue
    $previousNode = $currentNode
    Clear-Variable currentNode -ErrorAction SilentlyContinue
    $currentNode = $previousNode.NextOnLoop


    # direction we came from
    $directionOfMovement = $currentNode.PreviousOnLoop.DirectionOfMovement
    switch ($directionOfMovement) {
        'N' {
            $currentNode.IsInsideSW = $currentNode.PreviousOnLoop.IsInsideNW
            $currentNode.IsInsideSE = $currentNode.PreviousOnLoop.IsInsideNE
            if ($currentNode.DirectionOfMovement -eq 'W') {
                $currentNode.IsInsideNW = $currentNode.IsInsideSE
                $currentNode.IsInsideNE = $currentNode.IsInsideSE
            }
            elseif ($currentNode.DirectionOfMovement -eq 'E') {
                $currentNode.IsInsideNW = $currentNode.IsInsideSW
                $currentNode.IsInsideNE = $currentNode.IsInsideSW
            }
            else {
                #N
                $currentNode.IsInsideNW = $currentNode.IsInsideSW
                $currentNode.IsInsideNE = $currentNode.IsInsideSE
            }
            break
        }
        'E' {
            $currentNode.IsInsideNW = $currentNode.PreviousOnLoop.IsInsideNE
            $currentNode.IsInsideSW = $currentNode.PreviousOnLoop.IsInsideSE
            if ($currentNode.DirectionOfMovement -eq 'N') {
                $currentNode.IsInsideNE = $currentNode.IsInsideSW
                $currentNode.IsInsideSE = $currentNode.IsInsideSW
            }
            elseif ($currentNode.DirectionOfMovement -eq 'S') {
                $currentNode.IsInsideNE = $currentNode.IsInsideNW
                $currentNode.IsInsideSE = $currentNode.IsInsideNW

            }
            else {
                #E
                $currentNode.IsInsideNE = $currentNode.IsInsideNW
                $currentNode.IsInsideSE = $currentNode.IsInsideSW
            }
            break
        }
        'S' {
            $currentNode.IsInsideNW = $currentNode.PreviousOnLoop.IsInsideSW
            $currentNode.IsInsideNE = $currentNode.PreviousOnLoop.IsInsideSE
            if ($currentNode.DirectionOfMovement -eq 'W') {
                $currentNode.IsInsideSW = $currentNode.IsInsideNE
                $currentNode.IsInsideSE = $currentNode.IsInsideNE
            }
            elseif ($currentNode.DirectionOfMovement -eq 'E') {
                $currentNode.IsInsideSW = $currentNode.IsInsideNW
                $currentNode.IsInsideSE = $currentNode.IsInsideNW

            }
            else {
                #S
                $currentNode.IsInsideSW = $currentNode.IsInsideNW
                $currentNode.IsInsideSE = $currentNode.IsInsideNE
            }
            break
        }
        'W' {
            $currentNode.IsInsideNE = $currentNode.PreviousOnLoop.IsInsideNW
            $currentNode.IsInsideSE = $currentNode.PreviousOnLoop.IsInsideSW
            if ($currentNode.DirectionOfMovement -eq 'S') {
                $currentNode.IsInsideNW = $currentNode.IsInsideNE
                $currentNode.IsInsideSW = $currentNode.IsInsideNE
            }
            elseif ($currentNode.DirectionOfMovement -eq 'N') {
                $currentNode.IsInsideNW = $currentNode.IsInsideSE
                $currentNode.IsInsideSW = $currentNode.IsInsideSE
            }
            else {
                #W
                $currentNode.IsInsideNW = $currentNode.IsInsideNE
                $currentNode.IsInsideSW = $currentNode.IsInsideSE
            }
            break
        }
        default { throw "something wrong?" }
    }
} until ($currentNode.NextOnLoop.Id -eq $loopStartingPoint)



# Mark first row as edge
$allCells.Values | Where-Object { $_.Row -eq 0 } | ForEach-Object { $_.IsEdge = $true }

# Finally... Now we can look at all the undefined cells and place them either inside or outside
# We only need to look at the cell immediately north of us, since IF it IsLoop and has inside edges facing south
# We are on the inside.
for ($r = 1; $r -lt $rows; $r++) {
    for ($c = 0; $c -lt $cols; $c++) {
        $thisCell = $allCells["$r#$c"]

        if (!$thisCell.IsLoop) {
            $cellNorth = $allCells["$($r-1)#$c"]
            if ($cellNorth.IsLoop) {
                if ($cellNorth.IsInsideSW -or $cellNorth.IsInsideSE) {
                    $thisCell.IsEnclosed = $true
                }
                else {
                    $thisCell.IsEdge = $true
                }
            }
            else {
                $thisCell.IsEdge = $cellNorth.IsEdge
                $thisCell.IsEnclosed = $cellNorth.IsEnclosed
            }
        }
    }
}





PrintCells2 ([ref]$allCells) $rows $cols

$allCells.Values | Where-Object { $_.IsEnclosed } | Measure-Object
# final answer 579 