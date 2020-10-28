$testVersion = "v1.0.0"

Describe "Edge" {
    BeforeAll {
        $capturehash = $EdgeCaptureHash
        $EdgeFeaturesNotSupported = 'sslVpnConfig', 'SecurityGroup', 'MACSet', 'Ipv4Address', 'Ipv6Address'
        $t0MaxLimit = 160
        Write-Host "  --> Executing Edge tests for $TargetVersion"
    }

    AfterAll {
        Remove-Variable -Name CaptureHash
    }


    Context "Edge($testVersion): NSX-T Configuration Maximums" {
        It "Total number of Edge Services Gateways less than NSX-T T0 maximum of $t0MaxLimit" {
            ($capturehash.keys | Measure-Object).count | Should -BeLessOrEqual $t0MaxLimit
        }
    }

    foreach ($key in $capturehash.keys) {
        [xml]$xml = $capturehash.item($key)
        $item = $xml.edge
        $pesterDisplayName = "$($item.name)($($item.id))"
        Context "Edge($testVersion): Configuration: $pesterDisplayName" {
            It "SSLVPN Disabled" {
                $xml.edge.features.sslvpnConfig.enabled | Should -Not -Be "True"
            }

            It "OSPF Disabled" {
                $xml.edge.features.routing.ospf.enabled | Should -Not -Be "True"
            }
        }
    }
}

