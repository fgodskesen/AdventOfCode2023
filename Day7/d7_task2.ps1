$ErrorActionPreference = "Stop"
$rawData = Get-Content $PSScriptRoot\d7_input.txt
#$rawData = Get-Content $PSScriptRoot\d7_sample.txt



enum Hand {
    HighCard
    OnePair
    TwoPair
    ThreeOfAKind
    FullHouse
    FourOfAKind
    FiveOfAKind
}

$hands = $rawData | ForEach-Object {
    $cardsString = $_.Substring(0, 5)
    $bid = [int]$_.SubString(6)

    $handObject = [pscustomobject]@{
        HandString = $cardsString
        HandType   = [Hand]::HighCard
        HandHex    = $cardsString.Replace('A', 'e').Replace('K', 'd').Replace('Q', 'c').Replace('J', '1').Replace('T', 'a')
        HandInt    = 0
        Bid        = $bid
    }
    $handObject.HandInt = [uint]::Parse($handObject.HandHex, 'HexNumber')

    # Now lets go through the different ways a hand could be better than HighCard
    $grouping = @() + ($handObject.HandHex.ToCharArray() | Where-Object { $_ -ne [char]'1' } | Group-Object)

    $pairs = 0
    $trios = 0
    $quads = 0
    $quints = 0
    $grouping | ForEach-Object {
        if ($_.Count -eq 2) { $pairs++ }
        if ($_.Count -eq 3) { $trios++ }
        if ($_.Count -eq 4) { $quads++ }
        if ($_.Count -eq 5) { $quints++ }
    }

    $s = "{0},{1},{2},{3}" -f $pairs, $trios, $quads, $quints
    $handObject | Add-Member -MemberType NoteProperty -Name "S1" -Value $s

    # handle jokers
    $numJokers = (@() + ($handObject.HandHex.ToCharArray() | Where-Object { $_ -eq [char]'1' })).Count
    switch ($numJokers) {
        5 {
            $quints++; break
        } # fall through to 4
        4 {
            $quints++; break
        }
        3 {
            if ($pairs) { $quints++; $pairs-- }
            else { $quads++ }
            break
        }
        2 {
            if ($trios) { $quints++; $trios-- }
            elseif ($pairs) { $quads++; $pairs-- }
            else { $trios++ }
            break
        }
        1 {
            if ($quads) { $quints++; $quads-- }
            elseif ($trios) { $quads++; $trios-- }
            elseif ($pairs) { $trios++; $pairs-- }
            else { $pairs++ }
            break
        }
        default { break }
    }

    if ($quints) {
        $handObject.HandType = [Hand]::FiveOfAKind
    }
    elseif ($quads) {
        $handObject.HandType = [Hand]::FourOfAKind
    }
    elseif ($trios) {
        if ($pairs) {
            $handObject.HandType = [Hand]::FullHouse
        }
        else {
            $handObject.HandType = [Hand]::ThreeOfAKind
        }
    }
    elseif ($pairs -eq 2) {
        $handObject.HandType = [Hand]::TwoPair
    }
    elseif ($pairs) {
        $handObject.HandType = [Hand]::OnePair
    }
    $s = "{0},{1},{2},{3}" -f $pairs, $trios, $quads, $quints
    $handObject | Add-Member -MemberType NoteProperty -Name "S2" -Value $s
    $handObject | Add-Member -MemberType NoteProperty -Name "NJ" -Value $numJokers

    $handObject
}

$x = 1
$hands | Sort-Object HandType, HandInt | ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name "Rank" -Value $x -Force
    $x++
}

$hands | ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name "Winnings" -Value ($_.Bid * $_.Rank)
}

$hands | Measure-Object Winnings -Sum
#$hands | Out-GridView
# final result 250665248
