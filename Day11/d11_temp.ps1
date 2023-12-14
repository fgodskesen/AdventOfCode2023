$arr1 = (1..10000) | % {
    [pscustomobject]@{
        P1 = 1
        P2 = 2
        P3 = "Prop3"
    }
}
$arr2 = @() + (1..10000) | % {
    @(1, 2, "Prop3")
}


Measure-Command {
    for ($x = 0; $x -lt 10000; $x++) {
        $null = $arr1[$x].P1
        $null = $arr1[$x].P2
        $null = $arr1[$x].P3
    }
}

Measure-Command {
    for ($x = 0; $x -lt 30000; $x = $x + 3) {
        $null = $arr2[$x]
        $null = $arr2[$x + 1]
        $null = $arr2[$x + 2]
    }
}