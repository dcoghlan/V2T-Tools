$testVersion = "v1.0.0"
Describe "IPSets" {
    BeforeAll {
        $CaptureHash = $IpSetCaptureHash
        Write-Host "  --> Executing IP Set tests for $TargetVersion"

        $configMaxVer24 = @{
            "MaxIPSets"             = 10000
            "MaxIPSetEntries"       = 4000
            "MaxIPSetEntriesPolicy" = 500
        }

        $configMaxVer30 = @{
            "MaxIPSets"             = 10000
            "MaxIPSetEntries"       = 4000
            "MaxIPSetEntriesPolicy" = 500
        }
        
        $configMaxHash = @{
            "2.4" = $configMaxVer24
            "3.0" = $configMaxVer30
        }

        $invalidIpSetValues = "0.0.0.0", "255.255.255.255", "0.0.0.0/0", "0.0.0.0-255.255.255.255"
    }

    AfterAll {
        Remove-Variable -Name CaptureHash
    }

    Context "IPSets($testVersion): NSX-T Configuration Maximums" {
        It "Total number of IP Sets is less than $($configMaxHash[$TargetVersion]['MaxIPSets'])" {
            ($capturehash.keys | Measure-Object).count | Should BeLessThan $($configMaxHash[$TargetVersion]['MaxIPSets'])
        }
    }

    foreach ($key in $capturehash.keys) {
        [xml]$xml = $capturehash.item($key)
        $item = $xml.ipset
        $value = $item.value -split (',')
        $pesterDisplayName = "$($item.name)($($item.objectid))"
        Context "IPSets($testVersion): $pesterDisplayName" {
            It "IP Set must contain at least 1 entry: $($pesterDisplayName)" {
                ($item.value | Measure-Object).count | Should -BeGreaterOrEqual 1
            }
            It "IP Set contains no more than $($configMaxHash[$TargetVersion]['MaxIPSetEntries']) entries: $($pesterDisplayName)" {
                ($value | Measure-Object).count | Should -BeLessOrEqual $($configMaxHash[$TargetVersion]['MaxIPSetEntries'])
            }
            # It "IP Set contains no more than $($configMaxHash[$TargetVersion]['MaxIPSetEntriesPolicy']) entries (Policy Group static members): $($pesterDisplayName)" -Skip:(-not $($TargetVersion -eq "2.4") ) {
            It "IP Set contains no more than $($configMaxHash[$TargetVersion]['MaxIPSetEntriesPolicy']) entries (Policy Group static members): $($pesterDisplayName)" {
                ($value | Measure-Object).count | Should -BeLessOrEqual $($configMaxHash[$TargetVersion]['MaxIPSetEntriesPolicy'])
            }
            foreach ($ip in $value) {
                It "IP Set value must not contain invalid entries: $($ip)" {
                    $ip | Should -Not -BeIn $invalidIpSetValues
                }
            }
        }
    }


}