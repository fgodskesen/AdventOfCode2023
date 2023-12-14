

function DistributeItems ($numClusters, $numTotal) {
    # holds all the permutations
    $output = [System.Collections.ArrayList]::new()

    # holds just one permutation (current)
    $current = @()
    (1..$numClusters) | ForEach-Object { $current += 0 }
    $current[-1] = $numTotal

    # continue looping until the full $maxTotal have been put on the first cluster
    # pointer indicates which element are we looking at right now
    $output += $current -join ", "
    while ($current[0] -ne $numTotal) {
        # decrement last element by 1 unless it is 1 in which case we need to borrow (i.e. negative carry)
        if ($current[-1] -ge 1) {
            $current[-1]--
            $current[-2]++
        }
        else {
            # carry bit
            for ($pointer = $numClusters - 2; $pointer -gt 0; $pointer--) {
                if ($current[$pointer]) {
                    $current[-1] = $current[$pointer] - 1
                    $current[$pointer] = 0
                    $current[$pointer - 1]++
                    break
                }
            }
        }
        $output += $current -join ", "
    }
    $output
}
