$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d5_input.txt


###########################
# Begin parsing the input
###########################

# Prepopulate this array of "converters/maps" with a MapName which matches on something in the input txt
# Input and Output are used to determine which converter can apply to a given property, i.e. if you have 'soil', you can use converters that have 'soil' as Input, i.e. soil-to-fertilizer
$currentSection = "seeds:"
$seeds = @()
$maps = @(
    [pscustomobject]@{
        MapName  = "seed-to-soil map:"
        Input    = 'seed'
        Output   = "soil"
        Mappings = @()
    },
    [pscustomobject]@{
        MapName  = "soil-to-fertilizer map:"
        Input    = 'soil'
        Output   = "fertilizer"
        Mappings = @()
    },
    [pscustomobject]@{
        MapName  = "fertilizer-to-water map:"
        Input    = 'fertilizer'
        Output   = "water"
        Mappings = @()
    },
    [pscustomobject]@{
        MapName  = "water-to-light map:"
        Input    = 'water'
        Output   = "light"
        Mappings = @()
    },
    [pscustomobject]@{
        MapName  = "light-to-temperature map:"
        Input    = 'light'
        Output   = "temperature"
        Mappings = @()
    },
    [pscustomobject]@{
        MapName  = "temperature-to-humidity map:"
        Input    = 'temperature'
        Output   = "humidity"
        Mappings = @()
    },
    [pscustomobject]@{
        MapName  = "humidity-to-location map:"
        Input    = 'humidity'
        Output   = "location"
        Mappings = @()
    }
)



for ($x = 0; $x -lt $rawData.Count; $x++) {
    if ($x -gt 164) {
        if ($true) {}
    }


    if ($rawData[$x].Trim() -eq "") {
        # Ignore blank lines
    }
    elseif ($rawData[$x] -like '* map:') {
        # switch section
        $currentSection = $rawData[$x]
        continue
    }
    else {
        # Parse numbers
        switch ($currentSection) {
            'seeds:' {
                $seeds = $rawData[$x].SubString($currentSection.Length).Split(' ') | Where-Object { $_ -ne "" } | ForEach-Object { [int64]$_ }
                break
            }
            default {
                $parts = $rawData[$x].Split(" ").Trim() | Where-Object { $_ -ne "" } | ForEach-Object { [int64]$_ }
                $mapping = [pscustomobject]@{
                    Begin  = $parts[1]
                    End    = $parts[1] + $parts[2] - 1
                    Offset = $parts[0] - $parts[1]
                    #B2     = $parts[0]
                    #T2     = $parts[1]
                    #L2     = $parts[2]
                }
                ($maps | Where-Object { $_.MapName -eq $currentSection }).Mappings += $mapping
                break
            }
        }
    }
}

###########################
# END parsing the input
###########################



# Helper function to convert data for one or more seeds
function Convert-ElfData {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [int64[]]
        $Seed,

        # Parameter help description
        [Parameter(Mandatory, Position = 1)]
        $Maps
    )

    begin {}
    process {
        foreach ($item in $Seed) {
            $retObj = [pscustomobject]@{
                "seed" = $item
            }

            # Go through the maps one by one until there are no maps that can convert the currentInput
            $currentInput = 'seed'
            while ($Maps.Input -contains $currentInput) {
                $currentMap = $Maps | Where-Object { $_.Input -eq $currentInput }
                $inputValue = $retObj.$currentInput

                $mappingsThatMatch = @()
                $mappingsThatMatch += $currentMap.Mappings | Where-Object { ($_.Begin -le $inputValue) -and ($inputValue -le $_.End) }
                switch ($mappingsThatMatch.Count) {
                    0 {
                        $outputValue = $inputValue
                        $reason = "NoMap"
                        break
                    }
                    1 {
                        $outputValue = $inputValue + $mappingsThatMatch[0].Offset
                        $reason = "$($mappingsThatMatch[0].Begin)"
                        break
                    }
                    default {
                        throw "More than one mapping matched the input. Something must be wrong."
                        break
                    }
                }

                $retObj | Add-Member -MemberType NoteProperty -Name ("{0}-C" -f $currentMap.Output) -Value $reason
                $retObj | Add-Member -MemberType NoteProperty -Name $currentMap.Output -Value $outputValue
                $currentInput = $currentMap.Output
            }

            Write-Output $retObj
        }
    }

    end {}
}




$seeds | Convert-ElfData -Maps $maps | Sort-Object Location | Format-Table * -AutoSize

# final answer 3374647
<#
     seed soil-C           soil fertilizer-C fertilizer water-C         water light-C         light temperature-C temperature humidity-C   humidity location-C   location
      ---- ------           ---- ------------ ---------- -------         ----- -------         ----- ------------- ----------- ----------   -------- ----------   --------
   7535297 0           327167470 0            1440531588 1367341468 1387178887 1377596407  289995380 269134766        75361874 40127528    186491414 183116767     3374647
3229061264 3137203975 4133626578 4084049871   2488371029 2295076898 1004194120 724253805   654113257 650839196       969701866 946200429  1219888338 1167819222  386490336
1115055792 881086048  1539329921 1524404006    340834262 135850967  2510267983 NoMap      2510267983 2470409703     3068914674 3036573035 1341335047 1167819222  507937045
 280775197 195589471   316147946 0            1429512064 1367341468 1376159363 1044576172 1149214173 681820034       573743250 475089348   131580575 117989876   529571705
3663093536 3638948449 3984307701 3957001832   3289348829 NoMap      3289348829 2853491893 3672650890 3569882248     1997012425 1916586344 1484704953 1353364245  851820500
 241030710 195589471   276403459 0            1389767577 1367341468 1336414876 1044576172 1109469686 681820034       533998763 475089348    91836088 51914834   1227363756
1075412586 881086048  1499686715 1419317417     80369298 0          1258507098 1044576172 1031561908 681820034       456090985 287474851   737742452 724159097  1715134816
1532286286 1433058022  579860829 435632229     766127376 135850967  2935561097 2853491893 3318863158 3246339394     4180047286 4096840546 2365699881 2364759797 2084797298
 178275214 10243502   2627131518 2596751746   3419470771 NoMap      3419470771 3310417810 3166835353 3164913884     4268748681 4096840546 2454401276 2364759797 2173498693
2748861189 2660737044  959463716 871525822     193024483 135850967  2362458204 NoMap      2362458204 2338751966     2921104895 2698929267 2702795519 2698506361 2424858541
 412141395 377104678  2117170555 NoMap        2117170555 1938578086 1951878457 NoMap      1951878457 1822350940     1641862553 1605335670 3948172845 3865158152 2674377888
 424413807 377104678  2129442967 NoMap        2129442967 1938578086 1964150869 NoMap      1964150869 1822350940     1654134965 1605335670 3960445257 3865158152 2686650300
3430371306 3390401982 3883420816 3882716410   4135053620 4118877604 3722976790 3527291682 2815221079 2656521807     2578879816 2556336457 3989715459 3865158152 2715920502
 613340959 600174302  1768899525 1686398945   1631496927 1367341468 1578144226 1471356449 1735989368 1452421821     3733770013 3713321076 3532960445 3526559636 2866486785
 130341162 10243502   2579197466 2445770200   2892747379 2707086691 2216460934 NoMap      2216460934 2204259687     2775107625 2698929267 2556798249 2534368988 2906843672
 138606714 10243502   2587463018 2445770200   2901012931 2707086691 2224726486 NoMap      2224726486 2204259687     2783373177 2698929267 2565063801 2534368988 2915109224
 146351614 10243502   2595207918 2445770200   2908757831 2707086691 2232471386 NoMap      2232471386 2204259687     2791118077 2698929267 2572808701 2534368988 2922854124
 352550713 302559678  2434545841 2422248939   2748095754 2707086691 2071809309 NoMap      2071809309 1822350940     1761793405 1660861808 2919195256 2809960450 3128635582
  27275209 10243502   2476131513 2445770200   2789681426 2707086691 2113394981 NoMap      2113394981 1822350940     1803379077 1660861808 2960780928 2939975778 3161390382
  77896732 10243502   2526753036 2445770200   2840302949 2707086691 2164016504 NoMap      2164016504 1822350940     1854000600 1809540174 2094575437 2058767600 3846951716
#>
