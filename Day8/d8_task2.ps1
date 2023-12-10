$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d8_input.txt
#$rawData = Get-Content $PSScriptRoot\d8_sample.txt
#$rawData = Get-Content $PSScriptRoot\d8_sample2.txt

# Parse input into... something

$instructionSet = $rawData[0]
$instructionSetBinary = @()
for ($ix = 0; $ix -lt $instructionSet.Length; $ix++) {
    $instructionSetBinary += $instructionSet[$ix] -eq 'R'
}



$htNodes = @{}
for ($ix = 2; $ix -lt $rawData.Count; $ix++) {
    # sample: GLJ = (QQV, JTL)
    $key = $rawData[$ix].SubString(0, 3)
    $values = $rawData[$ix].SubString(7, 8).Split(',').Trim()

    $htNodes += @{
        $key = $values
    }
}


$htNodes2 = @{}
$steps = ""
foreach ($inNode in $htNodes.Keys) {
    $currentNodeId = $inNode
    $nodeObj = [pscustomobject]@{
        Id       = $currentNodeId
        Exits    = @()
        NextNode = ""

    }

    $ix = 0
    do {
        $steps += " $currentNodeId"
        if ($currentNodeId[2] -eq 'Z') {
            $nodeObj.Exits += $ix
        }
        $currentNodeId = $htNodes[$currentNodeId][$instructionSetBinary[$ix]]
        $ix++
    } until ($ix -ge $instructionSet.Length)
    $nodeObj.NextNode = $currentNodeId
    $htNodes2[$inNode] = $nodeObj
    break
}

break




break





class Ghosts {
    [string[]]$Positions
    [uint64]$Steps

    [hashtable]$Nodes
    [bool[]]$InstructionSet
    [bool]$CurrentInstruction
    [int]$Ptr

    Ghosts ($_Nodes, $_InstructionSet) {
        $this.Nodes = $_Nodes

        $inst = [System.Collections.ArrayList]::new()
        for ($ix = 0; $ix -le $_InstructionSet.Length; $ix++) {
            $null = $inst.Add(($_InstructionSet[$ix] -eq 'L'))
        }
        $this.InstructionSet = $inst.ToArray()

        $this.CurrentInstruction = $this.InstructionSet[0]
        $this.Positions = $this.Nodes.Keys | Where-Object { $_[2] -eq 'A' }
    }

    [bool] AreWeDone () {
        $isDone = $true
        foreach ($position in $this.Positions) {
            if ($position[2] -ne 'Z') {
                return $false
            }
        }
        return $isDone
    }


    MoveForward () {
        for ($ix = 0; $ix -lt $this.Positions.Count; $ix++) {
            $nodeName = $this.Positions[$ix]
            $node = $this.Nodes[$nodeName]
            $newNodeName = $node[($this.CurrentInstruction)]
            $this.Positions[$ix] = $newNodeName
        }
        $this.Steps++
        $this.Ptr = $this.Steps % $this.InstructionSet.Length
        $this.CurrentInstruction = $this.InstructionSet[$this.Ptr]

        if ($this.Steps % 10000 -eq 0) {
            Write-Host ("{0} - {1} {2}" -f ([string]$this.Steps).PadLeft(8, "0"), $this.CurrentInstruction, ($this.Positions -join " "))
        }
    }

    MoveAll () {
        while (!($this.AreWeDone())) {
            $this.MoveForward()
        }
    }
}


$ghostsInstance = [Ghosts]::new($htNodes, $instructionSet)

