$testVersion = "v1.0.0"
Describe "SecurityTags" {
    BeforeAll {
        $CaptureHash = $SecurityTagCaptureHash
        Write-Host "  --> Executing SecurityTag tests for $TargetVersion"
        $tagNameMaxLength = 256

        # $configMaxVer24 = @{
        #     "MaxIPSets"             = 10000
        #     "MaxIPSetEntries"       = 4000
        #     "MaxIPSetEntriesPolicy" = 500
        # }

        # $configMaxVer30 = @{
        #     "MaxIPSets"             = 10000
        #     "MaxIPSetEntries"       = 4000
        #     "MaxIPSetEntriesPolicy" = 500
        # }
        
        # $configMaxHash = @{
        #     "2.4" = $configMaxVer24
        #     "3.0" = $configMaxVer30
        # }

        # $invalidIpSetValues = "0.0.0.0", "255.255.255.255", "0.0.0.0/0", "0.0.0.0-255.255.255.255"
        $tagNameMaxLength = 256
    }

    AfterAll {
        Remove-Variable -Name CaptureHash
    }

    # Context "IPSets($testVersion): NSX-T Configuration Maximums" {
    #     It "Total number of IP Sets is less than $($configMaxHash[$TargetVersion]['MaxIPSets'])" {
    #         ($capturehash.keys | Measure-Object).count | Should BeLessThan $($configMaxHash[$TargetVersion]['MaxIPSets'])
    #     }
    # }

    foreach ($key in $capturehash.keys) {
        [xml]$xml = $capturehash.item($key)
        $item = $xml.SecurityTag
        $value = $item.value -split (',')
        $pesterDisplayName = "$($item.name)($($item.objectid))"

        Context "SecurityTags($testVersion): $pesterDisplayName" {
            It "Name contains less than $tagNameMaxLength characters" -Skip:$(Invoke-RequiredVersionCheck -required "2.0" -TargetVersion $TargetVersion) {
                $item.name.length | Should -BeLessOrEqual $tagNameMaxLength
            }
        }
    }


}