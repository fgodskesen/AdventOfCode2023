

function PermutateLine ($str) {
    $firstUnknown = $str.IndexOf("?")
    if ($firstUnknown -eq -1) {
        $str
    }
    else {
        PermutateLine $str.Substring($firstUnknown + 1) | ForEach-Object {
            $str.SubString(0, $firstUnknown) + "#" + $_
        }
        PermutateLine $str.Substring($firstUnknown + 1) | ForEach-Object {
            $str.SubString(0, $firstUnknown) + "." + $_
        }
    }
}


function PermutateLine2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Broken,

        [Parameter(Mandatory)]
        [string]$Springs
    )

    begin {}
    process {}
    end {
        $totalBroken = 0
        $Broken | ForEach-Object { $totalBroken += $_ }

        $mandatorySpaceCount = $Broken.Count - 1

        # These are essentially $spacesThatCanBeDistributed '.'s that can be distributed on the string. We remove 1 for each space between #'s as there must be
        # space between each cluster of broken springs.
        # this gives us an array of numbers which represent how many "."s to draw, 
        # i.e.
        # 1 0 1 with $broken = 2 2 would give us a string like ".##.##."
        # 4 0 1 with $broken = 3 2 would give us a string like "....###.##."

        $spacesThatCanBeDistributed = $Springs.Length - $totalBroken - $mandatorySpaceCount


        # put some 
        $spaces = @(0)
        $numberCount | ForEach-Object { $spaces += 1 }

        #$spaces += 
    }
}


