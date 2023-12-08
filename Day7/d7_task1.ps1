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
        HandHex    = $cardsString.Replace('A', 'e').Replace('K', 'd').Replace('Q', 'c').Replace('J', 'b').Replace('T', 'a')
        HandInt    = 0
        Bid        = $bid
    }
    $handObject.HandInt = [uint]::Parse($handObject.HandHex, 'HexNumber')

    # Now lets go through the different ways a hand could be better than HighCard
    $grouping = $handObject.HandHex.ToCharArray() | Group-Object
    if ($grouping | Where-Object { $_.Count -eq 5 }) {
        $handObject.HandType = [Hand]::FiveOfAKind
    }
    elseif ($grouping | Where-Object { $_.Count -eq 4 }) {
        $handObject.HandType = [Hand]::FourOfAKind
    }
    elseif ($grouping | Where-Object { $_.Count -eq 3 }) {
        if ($grouping | Where-Object { $_.Count -eq 2 }) {
            $handObject.HandType = [Hand]::FullHouse
        }
        else {
            $handObject.HandType = [Hand]::ThreeOfAKind
        }
    }
    elseif ( (@() + ($grouping | Where-Object { $_.Count -eq 2 })).Count -eq 2) {
        $handObject.HandType = [Hand]::TwoPair
    }
    elseif ($grouping | Where-Object { $_.Count -eq 2 }) {
        $handObject.HandType = [Hand]::OnePair
    }

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

# final result 250120186
