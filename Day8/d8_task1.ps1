$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d8_input.txt
#$rawData = Get-Content $PSScriptRoot\d8_sample.txt

# Parse input into... something

$instructionSet = $rawData[0]
#$instructionSetBinary = $rawData[0].Replace('L', 0).Replace('R', 1)

$htNodes = @{}
for ($ix = 2; $ix -lt $rawData.Count; $ix++) {
    # sample: GLJ = (QQV, JTL)
    $key = $rawData[$ix].SubString(0, 3)
    $values = $rawData[$ix].SubString(7, 8).Split(',').Trim()

    $htNodes += @{
        $key = $values
    }
}



# Now go through the instructions one by one... repeating if needed, until currentNode is ZZZ


$currentNodeName = 'AAA'
$steps = 0
while ($currentNodeName -ne 'ZZZ') {
    $currentInstruction = $instructionSet[($steps % ($instructionSet.Length))]
    $currentNode = $htNodes[$currentNodeName]
    $newNodeName = $currentInstruction -eq 'L' ? $currentNode[0] : $currentNode[1]
    #Write-Host "I:$currentInstruction N:$($currentNodeName):$($currentNode -join "-") -> $newNodeName"
    $currentNodeName = $newNodeName
    $steps++
}


Write-Host "$steps Steps"
# final answer 14681
