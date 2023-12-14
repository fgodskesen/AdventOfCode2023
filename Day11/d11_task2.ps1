$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d11_input.txt

#$rawData = Get-Content $PSScriptRoot\d11_sample.txt
# Expected result: 374

class Galaxy {
    hidden [int]$_Id = $(
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

    Galaxy($_Row, $_Col, $_Id, $_Map) {
        $this._Row = $_Row
        $this._Col = $_Col
        $this._Id = $_Id
        $this._Map = $_Map
    }
}

class Map {
    hidden [array]$_Galaxies = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'Galaxies' -Value { $this._Galaxies
        } -SecondValue { throw "Parameter is ReadOnly" }
    )
    hidden [int[]]$_EmptyRows = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'EmptyRows' -Value { $this._EmptyRows
        } -SecondValue { throw "Parameter is ReadOnly" }
    )
    hidden [int[]]$_EmptyCols = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'EmptyCols' -Value { $this._EmptyCols
        } -SecondValue { throw "Parameter is ReadOnly" }
    )


    Map ($_InputData) {
        # Populate Map with Galaxies. Ignore empty space
        $this._Galaxies = @()
        $id = 0
        for ($r = 0; $r -lt $_InputData.Count; $r++) {
            for ($c = 0; $c -lt $_InputData[0].Length; $c++) {
                if ($_InputData[$r][$c] -eq '#') {
                    $gx = [Galaxy]::new($r, $c, $id, $this)
                    $this._Galaxies += $gx
                    $id++
                }
            }
        }

        # Determine empty rows
        $temp = @()
        for ($r = 0; $r -lt $_InputData.Count; $r++) {
            if ($_InputData[$r] -match "^[\.]+$") { $temp += $r }
        }
        $this._EmptyRows = $temp
        $this._EmptyCols = @()
        for ($c = 0; $c -lt $_InputData[0].Length; $c++) {
            $column = ($_InputData | ForEach-Object { $_[$c] }) -join ""
            if ($column -match "^[\.]+$") { $this._EmptyCols += $c }
        }
    }

    PrintMap () {
        Invoke-PrintMap ($this)
    }
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



Write-Host "Load universe"
$MyMap = [Map]::new($rawData)
Write-Host "Done"


Write-Host "Find all pairs and distance between them."
$pairs = [System.Collections.ArrayList]::new()
<#
for ($ix1 = 0; $ix1 -lt $MyMap.Galaxies.Count - 1; $ix1++) {
    Write-Host $ix1
    $cell1 = $MyMap.Galaxies[$ix1]
    for ($ix2 = $ix1 + 1; $ix2 -lt $MyMap.Galaxies.Count; $ix2++) {
        $cell2 = $MyMap.Galaxies[$ix2]

        $cost = 0
        $rowsToCross = ($cell1.Row..$cell2.Row) | Where-Object { $_ -ne $cell1.Row }
        # each row costs 1 to cross unless it is an empty row in which case it costs 10^6
        foreach ($row in $rowsToCross) {
            if ($row -in $cell1.Map.EmptyRows) {
                $cost += 2
            }
            else {
                $cost += 1
            }
        }

        $colsToCross = ($cell1.Col..$cell2.Col) | Where-Object { $_ -ne $cell1.Col }
        # each row costs 1 to cross unless it is an empty row in which case it costs 10^6
        foreach ($col in $colsToCross) {
            if ($row -in $cell1.Map.EmptyCol) {
                $cost += 2
            }
            else {
                $cost += 1
            }
        }

        $pair = [pscustomobject]@{
            A_ID  = [int]$cell1.Id + 1
            A_Row = $cell1.Row
            A_Col = $cell1.Col
            B_Id  = [int]$cell2.Id + 1
            B_Row = $cell2.Row
            B_Col = $cell2.Col
            Cost  = $cost
        }
        $pairs += $pair

    }
}
#>
$totalCost = 0
for ($ix1 = 0; $ix1 -lt $MyMap.Galaxies.Count - 1; $ix1++) {
    Write-Host $totalCost
    $cell1 = $MyMap.Galaxies[$ix1]
    for ($ix2 = $ix1 + 1; $ix2 -lt $MyMap.Galaxies.Count; $ix2++) {


        $cell2 = $MyMap.Galaxies[$ix2]

        $cost = 0

        $cost += [Math]::Abs($cell1.Row - $cell2.Row)
        $cost += [Math]::Abs($cell1.Col - $cell2.Col)

        # add an extra something foreach empty row or column we pass
        foreach ($r in $cell1.Map.EmptyRows) {
            if ($r -ge $cell1.Row -and $r -le $cell2.Row) {
                $cost += 999999
            }
        }
        foreach ($c in $cell1.Map.EmptyCols) {
            if ($c -ge [Math]::Min($cell1.Col, $cell2.Col) -and $c -le [Math]::Max($cell1.Col, $cell2.Col)) {
                $cost += 999999
            }
        }

        <#
        $pair = [pscustomobject]@{
            A_ID  = [int]$cell1.Id + 1
            A_Row = $cell1.Row
            A_Col = $cell1.Col
            B_Id  = [int]$cell2.Id + 1
            B_Row = $cell2.Row
            B_Col = $cell2.Col
            Cost  = $cost
        }
        $pairs += $pair
        #>
        $totalCost += $cost
    }
}

$totalCost
# actual input, 568914596391

