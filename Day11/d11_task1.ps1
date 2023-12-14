$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d11_input.txt

#$rawData = Get-Content $PSScriptRoot\d11_sample.txt
# Expected result: 374


#Between galaxy 1 and galaxy 7: 15
#$galaxies[0].Distances[$galaxies[6].Id]

# Between galaxy 3 and galaxy 6: 17
#$galaxies[2].Distances[$galaxies[5].Id]

# Between galaxy 8 and galaxy 9: 5
#$galaxies[7].Distances[$galaxies[8].Id]




# find empty rows or columns
$emptyRows = @()
$emptyCols = @()
$rows = $rawData.Count
$cols = $rawData[0].Length
for ($r = 0; $r -lt $rows; $r++) {
    if ($rawData[$r] -match "^[\.]+$") { $emptyRows += $r }
}
for ($c = 0; $c -lt $cols; $c++) {
    $column = ($rawData | ForEach-Object { $_[$c] }) -join ""
    if ($column -match "^[\.]+$") { $emptyCols += $c }
}

Write-Host "Expanding universe in rows $($emptyRows -join ", ")"
Write-Host "Expanding universe in columns $($emptyCols -join ", ")"

# "Expand" the universe, i.e., double any empty row or column
$expandedData = [System.Collections.ArrayList]::new()
for ($r = 0; $r -lt $rows; $r++) {
    if ($r -in $emptyRows) {
        $null = $expandedData.Add(("." * ($cols + $emptyCols.Count)))
        $null = $expandedData.Add(("." * ($cols + $emptyCols.Count)))
    }
    else {
        $line = ""
        for ($c = 0; $c -le $cols; $c++) {
            if ($c -in $emptyCols) { $line += ".." }
            else { $line += $rawData[$r][$c] }
        }
        $null = $expandedData.Add($line)
    }
}




class Cell {
    hidden [string]$_Id = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Id' -Value { $this._Id
        } -SecondValue { throw "Parameter is ReadOnly" }
    )
    hidden [int]$_Row = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Row' -Value { $this._Row
        } -SecondValue { throw "Parameter is ReadOnly" }
    )
    hidden [int]$_Col = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Col' -Value { $this._Col
        } -SecondValue { throw "Parameter is ReadOnly" }
    )
    hidden [Map]$_Map = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Map' -Value { $this._Map
        } -SecondValue { throw "Parameter is ReadOnly" }
    )

    hidden [array]$_Connections = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Connections' -Value {
            if (!$this._Connections.Count) {
                Invoke-GetNeighbors $this
            }
            $this._Connections
        } -SecondValue {
            throw "Parameter is ReadOnly"
        }
    )

    hidden [hashtable]$_Distances = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Distances' -Value {
            if (!$this._Distances.Keys) {
                #Invoke-GetDijkstra $this
                Invoke-GetDistancesFast $this
            }
            $this._Distances
        } -SecondValue {
            throw "Parameter is ReadOnly"
        }
    )

    [char]$Symbol
    [bool]$IsGalaxy = $false

    Cell($_Row, $_Col, $_Symbol, $_Map) {
        $this._Row = $_Row
        $this._Col = $_Col
        $this._Id = "$_Row#$_Col"
        $this._Map = $_Map
        $this.Symbol = $_Symbol
        if ($_Symbol -eq '#') { $this.IsGalaxy = $true }
    }
}

class Map {
    hidden $_Rows = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Rows' -Value {
            $this._Rows } -SecondValue { throw "Parameter is ReadOnly" }
    )
    hidden $_Cols = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Cols' -Value {
            $this._Cols } -SecondValue { throw "Parameter is ReadOnly" }
    )

    [hashtable]$Cells = @{}

    [Cell] GetCell ($_Row, $_Col) {
        return $this.Cells["$_Row#$_Col"]
    }

    [Cell[]] GetCells () {
        return $this.Cells.Values
    }

    SetCell ($_Row, $_Col, $_Value) {
        $this.Cells["$_Row#$_Col"] = $_Value
    }

    Map ($_RawData) {
        $this._Rows = $_RawData.Count
        $this._Cols = $_RawData[0].Length

        # Populate Map with Cells
        for ($r = 0; $r -lt $this.Rows; $r++) {
            for ($c = 0; $c -lt $this.Cols; $c++) {
                $newCell = [Cell]::new($r, $c, $_RawData[$r][$c], $this)
                $this.Cells.Add($newCell.Id, $newCell)
            }
        }
    }

    <#
    FindEmptySpaces () {
        Invoke-FindEmptySpaces ($this)
    }
    #>

    PrintMap () {
        Invoke-PrintMap ($this)
    }
}



function Invoke-GetNeighbors ([Cell]$Cell) {
    $retVal = @()
    if ($Cell.Row -gt 0) {
        $retVal += [pscustomobject]@{
            Direction = 'N'
            #Cost      = if ($Cell.Symbol -in @('-', '+')) { 3 } else { 2 }
            Id        = "$($Cell.Row - 1)#$($Cell.Col)"
        }
    }
    if ($Cell.Col -lt $Cell.Map.Cols - 1) {
        $retVal += [pscustomobject]@{
            Direction = 'E'
            #Cost      = if ($this.Symbol -in @('|', '+')) { 3 } else { 2 }
            Id        = "$($Cell.Row)#$($Cell.Col + 1)"
        }
    }
    if ($Cell.Row -lt $Cell.Map.Rows - 1) {
        $retVal += [pscustomobject]@{
            Direction = 'S'
            #Cost      = if ($this.Symbol -in @('-', '+')) { 3 } else { 2 }
            Id        = "$($Cell.Row + 1)#$($Cell.Col)"
        }
    }
    if ($Cell.Col -gt 0) {
        $retVal += [pscustomobject]@{
            Direction = 'W'
            #Cost      = if ($this.Symbol -in @('|', '+')) { 3 } else { 2 }
            Id        = "$($Cell.Row)#$($Cell.Col-1)"
        }
    }
    $Cell._Connections = $retVal
}

function Invoke-GetDijkstra ([Cell]$Cell) {
    # https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
    $nodes = @{}

    # Step 1, assign infinite distance to all nodes and mark them as unvisited
    foreach ($itm in $Cell.Map.GetCells()) {
        $obj = [pscustomobject]@{
            Id       = $itm.Id
            Distance = [int]::MaxValue
        }
        $nodes.Add($itm.Id, $obj)
    }

    # TODO Make a smaller set of unvisited nodes that we add/remove neighbors to
    #$unvisitedNodes = [System.Collections.Generic.HashSet[string]]::new()

    # Step 2, assign distance 0 to starting node. Set currentNode to starting node
    $nodes[$Cell.Id].Distance = 0
    $currentNode = $nodes[$Cell.Id]
    $shouldStop = $false
    do {
        # For current node, look at all unvisited neighbors and update their tentative distance
        # use the lower of the current value and the new value
        $unvisitedNeighbors = $Cell.Map.Cells[$currentNode.Id].Connections | Where-Object { !($nodes[$_.Id].IsVisited) }
        foreach ($neighbor in $unvisitedNeighbors) {
            $neighborId = $neighbor.Id
            $neighborCost = 1 #$neighbor.Cost
            $newDistance = $currentNode.Distance + $neighborCost


            # update neighbors distance if applicable
            $nodes[$neighborId].Distance = [Math]::Min($nodes[$neighborId].Distance, $newDistance)
        }

        # Mark currentnode as visited
        $currentNode.IsVisited = $true

        # and pick a new currentnode from among the unvisited neighbors, sorted by Distance
        $currentNode = $nodes.Values | Where-Object { !$_.IsVisited } | Sort-Object Distance | Select-Object -First 1
        if (!$currentNode) { $shouldStop = $true }
        elseif (!($nodes | Where-Object { !$_.IsVisited })) { $shouldStop = $true }
        elseif ($currentNode.Distance -eq [int]::MaxValue) { $shouldStop = $true }
    } until ($shouldStop)
    $Cell._Distances = $nodes
}

function Invoke-GetDistancesFast ([Cell]$Cell) {
    $nodes = @{}

    for ($r = 0; $r -lt $Cell.Map.Rows; $r++) {
        for ($c = 0; $c -lt $Cell.Map.Cols; $c++) {
            $obj = [pscustomobject]@{
                Id        = "$r#$c"
                Distance  = [Math]::Abs($r - $Cell.Row) + [Math]::Abs($c - $Cell.Col)
                IsVisited = $true
            }
            $nodes.Add($obj.Id, $obj)
        }
    }
    $Cell._Distances = $nodes
}



function Invoke-PrintMap ($Map) {
    for ($r = 0; $r -lt $Map.Rows; $r++) {
        for ($c = 0; $c -lt $Map.Cols; $c++) {
            $element = $Map.Cells["$r#$c"]
            $fc = @{ForegroundColor = "White" }
            if ($element.Symbol -match '\d') {
                $fc = @{ForegroundColor = "Red" }
            }
            Write-Host $element.Symbol -NoNewline @fc
        }
        Write-Host ""
    }
}



Write-Host "Load expanded universe"
$MyMap = [Map]::new($expandedData)
Write-Host "Done"


$pairs = @()
$galaxies = $MyMap.GetCells() | Where-Object { $_.IsGalaxy } | Sort-Object Row, Col
Write-Host "$($galaxies.Count) galaxies found."

Write-Host "Numbering Galaxies"
for ($ix = 0; $ix -lt $galaxies.Count; $ix++) { $galaxies[$ix].Symbol = "$(($ix + 1 ) % 10 )" }


Write-Host "Find all pairs"
for ($ix1 = 0; $ix1 -lt $galaxies.Count - 1; $ix1++) {
    Write-Host "Galaxy A: $ix1"
    $cell1 = $galaxies[$ix1]
    for ($ix2 = $ix1 + 1; $ix2 -lt $galaxies.Count; $ix2++) {
        $cell2 = $galaxies[$ix2]
        $pair = [pscustomobject]@{
            ID1      = $cell1.Id
            Num1     = $ix1 + 1
            ID2      = $cell2.Id
            Num2     = $ix2 + 1
            Distance = [Math]::Abs($cell1.Row - $cell2.Row) + [Math]::Abs($cell1.Col - $cell2.Col)
            #$cell1.Distances[$cell2.Id].Distance
        }
        $pairs += $pair
    }
}

$MyMap.PrintMap()
$pairs | Measure-Object Distance -Sum

#Final answer: 9734203
