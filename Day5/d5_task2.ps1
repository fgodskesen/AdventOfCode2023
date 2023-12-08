$ErrorActionPreference = "Stop"

$rawData = Get-Content $PSScriptRoot\d5_input.txt


###########################
# Begin parsing the input
###########################
class MyRange {
    [uint64]$seed_begin
    [uint64]$seed_end
    [uint64]$soil_begin
    [uint64]$soil_end
    [uint64]$fertilizer_begin
    [uint64]$fertilizer_end
    [uint64]$water_begin
    [uint64]$water_end
    [uint64]$light_begin
    [uint64]$light_end
    [uint64]$temperature_begin
    [uint64]$temperature_end
    [uint64]$humidity_begin
    [uint64]$humidity_end
    [uint64]$location_begin
    [uint64]$location_end
    [string]$currentStep = 'seed'

    MyRange ($_Begin, $_End) {
        $this.seed_begin = $_Begin
        $this.seed_end = $_End
    }

    MyRange () {}

    [MyRange] Clone () {
        $newOutput = [MyRange]::new()
        $this | Get-Member -MemberType Property | ForEach-Object {
            $newOutput.$($_.Name) = $this.$($_.Name)
        }
        return $newOutput
    }
}




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

# on each map, fill in blanks with offset 0 entries
foreach ($map in $maps) {
    
    # Sort them first. Then we can fill in blanks and sort again
    $map.Mappings = $map.Mappings | Sort-Object Begin
    $toAdd = @()


    # do we need to add one from 0? This handles the first entry in the array as we now do not need to compare to a nonexistent item
    if (0 -lt $map.Mappings[0].Begin) {
        $toAdd += [pscustomobject]@{
            Begin  = 0
            End    = $map.Mappings[0].Begin - 1
            Offset = 0
        }
    }

    for ($ix = 1; $ix -lt $map.Mappings.Count; $ix ++) {
        $thisItem = $map.Mappings[$ix]
        $prevItem = $map.Mappings[$ix - 1]

        if (($thisItem.Begin - 1) -ne ($prevItem.End)) {
            $toAdd += [pscustomobject]@{
                Begin  = $prevItem.End + 1
                End    = $thisItem.Begin - 1
                Offset = 0
            }
        }

    }

    # do we need to add one from x to [uint64]::maxvalue? This handles the last entry in the array
    if ([uint64]::maxvalue -gt $map.Mappings[-1].End) {
        $toAdd += [pscustomobject]@{
            Begin  = $map.Mappings[-1].End + 1
            End    = [uint64]::maxvalue
            Offset = 0
        }
    }

    $toAdd | ForEach-Object { $map.Mappings += $_ }

    $map.Mappings = $map.Mappings | Sort-Object Begin


}

$seedRanges = @()
for ($x = 0; $x -lt $seeds.Count; $x += 2) {
    $seedRanges += [MyRange]::new($seeds[$x], $seeds[$x] + $seeds[$x + 1] - 1)
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
        [MyRange[]]
        $SeedRange,

        # Parameter help description
        [Parameter(Mandatory, Position = 1)]
        $Maps
    )

    begin {
        $todoList = [System.Collections.ArrayList]::new()
    }
    process {
        foreach ($range in $SeedRange) {
            $null = $todoList.Add($range)
        }
    }

    end {
        while (($todoList | Where-Object { $_.CurrentStep -ne "location" }).Count -gt 0 ) {
            $currentWorkItem = $todoList | Where-Object { $_.CurrentStep -ne "location" } | Select-Object -First 1
            $todoList.Remove($currentWorkItem)

            # Extract some info around this item
            $currentStep = $currentWorkItem.CurrentStep

            # find suitable mapper
            $correctMap = $Maps | Where-Object { $_.Input -eq $currentWorkItem.CurrentStep }

            $nextStep = $correctMap.Output


            $rangeToResolve_Begin = $currentWorkItem."$($currentStep)_begin"
            $rangeToResolve_End = $currentWorkItem."$($currentStep)_end"

            # we will move the toResolve_Begin mark up as we find suitable mappings for it.
            # I.e. it starts at the actual beginning of the range to resolve. If a mapping only covers parts of the entire range
            # we move it up until a new mapping takes over
            while ($rangeToResolve_Begin -lt $rangeToResolve_End) {
                $correctMapping = $correctMap.Mappings | Where-Object { ($_.Begin -le $rangeToResolve_Begin) -and ($rangeToResolve_Begin -le $_.End) } | Select-Object -First 1

                # Clone a new object to output
                $newOutput = $currentWorkItem.Clone()
                $newOutput."$($currentStep)_begin" = $rangeToResolve_Begin
                $newOutput."$($currentStep)_end" = [math]::Min($rangeToResolve_End, $correctMapping.End)
                $newOutput."$($nextStep)_begin" = $newOutput."$($currentStep)_begin" + $correctMapping.Offset
                $newOutput."$($nextStep)_end" = $newOutput."$($currentStep)_end" + $correctMapping.Offset
                $newOutput.CurrentStep = $nextStep

                #$newOutput | Format-Table
                $null = $todoList.Add($newOutput)

                $rangeToResolve_Begin = $newOutput."$($currentStep)_end" + 1
            }
        }
        $todoList
    }
}




$seedRanges | Convert-ElfData -Maps $maps | select seed*, location* | sort location_begin | ft * -AutoSize

#| Sort-Object Location | Format-Table * -AutoSize
