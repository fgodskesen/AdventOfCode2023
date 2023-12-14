
function PermutateSprings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [array]$BrokenSpringNumbers,

        [Parameter(Mandatory)]
        [int]$FieldLength
    )
    begin {}
    process {}
    end {
        # assuming all input is valid,
        # lets figure out all the different combinations of the numbers vs. the length of the string
        # i.e., if string is 6 chars and numbers are 2, 3. then this can only be ##.###
        # if numbers are 1,3, it could be  #..### or .#.### or #.###.

        # We do this by distributing the OKs instead of the broken springs, in other words, in the example above, 
        # we have 2 clusters of broken springs. This means 3 clusters of OK springs, of which the first and last have minimum value 0 and the middle one minimum 1
        $totalBad = 0; $BrokenSpringNumbers | ForEach-Object { $totalBad += $_ }
        $totalOk = $FieldLength - $totalBad

        # how many clusters of OK springs are there
        $numOkClusters = $BrokenSpringNumbers.Count + 1

        # and how many springs do we need to distribute to each cluster, not counting the mandatory minimum 1 between broken springs
        $totalOkSpringsToDistribute = $totalOk - ($numOkClusters - 2)

        # Get all combinations of that
        $permutations = DistributeItems $numOkClusters $totalOkSpringsToDistribute

        # and combine this into new strings
        foreach ($perm in $permutations) {
            $outString = ""

            $clusters = $perm.Split(", ") | % { [int]$_ }
            # Increment all "internal" ones by the mandatory minumum 1
            for ($ix = 1; $ix -lt $clusters.Count - 1; $ix++) {
                $clusters[$ix]++
            }

            for ($ix = 0; $ix -lt $clusters.Count - 1; $ix++) {
                $outString += "." * $clusters[$ix]
                $outString += "#" * ($BrokenSpringNumbers[$ix])
            }
            $outString += "." * $clusters[-1]
            $outString
        }
    }
}
