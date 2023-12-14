function Factorial ([int]$x) {
    $arr = @(
        1,
        1,
        2,
        6,
        24,
        120,
        720,
        5040,
        40320,
        362880,
        3628800,
        39916800,
        479001600,
        1932053504
    )
    if ($x -lt 0) { throw [ArithmeticException]("negative faculty") }
    elseif ($x -gt $arr.Count) { throw [System.OverflowException]("Too large a number") }
    else { $arr[$x] }
}