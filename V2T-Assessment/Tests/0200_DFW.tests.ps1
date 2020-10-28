$testVersion = "v1.0.0"

Describe "DFW" {
    BeforeAll {
        $SrcDstFieldObjectLimit = 128
        $AppliedToFieldObjectLimit = 128
        $maxDfwRulesLimit = 100000
        $maxDfwSectionsLimit = 10000
        $rawIpAddressTypes = "Ipv4Address", "Ipv6Address"
        $invalidIpValues = "0.0.0.0", "255.255.255.255", "0.0.0.0/0", "0.0.0.0-255.255.255.255"
        $eligibleForMigrationSrcDst = 'IPSet', 'SecurityGroup', 'MACSet', 'Ipv4Address', 'Ipv6Address', 'VirtualWire'
        $eligibleForMigrationAppliedTo = 'DISTRIBUTED_FIREWALL', 'Edge', 'SecurityGroup', 'VirtualWire', 'DistributedVirtualPortgroup'
        Write-Host "  --> Executing DFW tests for $TargetVersion"
    }
    
    AfterAll {
    
    }

    Context "DFW($testVersion): NSX-T Configuration Maximums" {
        It "Total number of DFW rules less than $maxDfwRulesLimit" {
            $layer3RuleCount = ($DfwConfigExportXML.firewallConfiguration.layer3Sections.section.rule | Measure-Object).count
            $layer2RuleCount = ($DfwConfigExportXML.firewallConfiguration.layer2Sections.section.rule | Measure-Object).count
            ($layer3RuleCount + $layer2RuleCount) | Should -BeLessOrEqual $maxDfwRulesLimit
        }
        It "Total number of DFW Sections less than $maxDfwSectionsLimit" {
            $layer3SectionCount = ($DfwConfigExportXML.firewallConfiguration.layer3Sections.section | Measure-Object).count
            $layer2SectionCount = ($DfwConfigExportXML.firewallConfiguration.layer2Sections.section | Measure-Object).count
            ($layer3SectionCount + $layer2SectionCount) | Should -BeLessOrEqual $maxDfwSectionsLimit
        }
    }

    foreach ($rule in ($DfwConfigExportXML.firewallConfiguration.layer3Sections.section.rule | Where-Object { $_ -ne $null })) {
        $pesterDisplayName = "RuleId: $($rule.id)"
        if ($rule | Get-Member -MemberType Property -Name name) {
            $pesterDisplayName = "$pesterDisplayName - $($Rule.name)"
        }

        Context "DFW($testVersion): Configuration - Layer3Sections: $pesterDisplayName" {
            if ($rule.sources) {
                It "Src contains less than $SrcDstFieldObjectLimit objects." {
                    ($rule.sources.source | Measure-Object).count | Should -BeLessOrEqual $SrcDstFieldObjectLimit
                }

                foreach ($source in $rule.sources.source) {
                    It "Src contains only objects supported by NSX-T: $($source.type) - $($source.name) ($($source.value))" {
                        $source.type | Should -BeIn $eligibleForMigrationSrcDst
                    }

                    if ($rawIpAddressTypes -contains $source.type) {
                        foreach ($rawValue in $source.value) {
                            It "Raw IP value used in rule src is valid ($rawValue)" {
                                $rawValue | Should -Not -BeIn $invalidIpValues
                            }
                        }
                    }
                }
            }
            if ($rule.destinations) {
                It "Dst contains less than $SrcDstFieldObjectLimit objects." {
                    ($rule.destinations.destination | Measure-Object).count | Should -BeLessOrEqual $SrcDstFieldObjectLimit
                }
                foreach ($destination in $rule.destinations.destination) {
                    It "Dst contains only objects supported by NSX-T: $($destination.type) - $($destination.name) ($($destination.value))" {
                        $destination.type | Should -BeIn $eligibleForMigrationSrcDst
                    }

                    if ($rawIpAddressTypes -contains $destination.type) {
                        foreach ($rawValue in $destination.value) {
                            It "Raw IP value used in rule dst is valid ($rawValue)" {
                                $rawValue | Should -Not -BeIn $invalidIpValues
                            }
                        }
                    }
                }
            }
            if ($rule.appliedToList) {
                It "Applied To contains less than $AppliedToFieldObjectLimit objects." {
                    ($rule.appliedToList.appliedTo | Measure-Object).count | Should -BeLessOrEqual $AppliedToFieldObjectLimit
                }
                foreach ($appliedTo in $rule.appliedToList.appliedTo) {
                    It "AppliedToContains only objects supported by NSX-T: $($appliedTo.type) - $($appliedTo.name) ($($appliedTo.value))" {
                        $appliedTo.type | Should -BeIn $eligibleForMigrationAppliedTo
                    }
                }
            }
        }
    }

    foreach ($rule in ($DfwConfigExportXML.firewallConfiguration.layer2Sections.section.rule | Where-Object { $_ -ne $null })) {
        $pesterDisplayName = "RuleId: $($rule.id)"
        if ($rule | Get-Member -MemberType Property -Name name) {
            $pesterDisplayName = "$pesterDisplayName - $($Rule.name)"
        }

        Context "DFW($testVersion): Configuration - Layer2Sections: $pesterDisplayName" {
            if ($rule.sources) {
                It "Src contains less than $SrcDstFieldObjectLimit objects." {
                    ($rule.sources.source | Measure-Object).count | Should -BeLessOrEqual $SrcDstFieldObjectLimit
                }

                foreach ($source in $rule.sources.source) {
                    It "Src contains only objects supported by NSX-T: $($source.type) - $($source.name) ($($source.value))" {
                        $source.type | Should -BeIn $eligibleForMigrationSrcDst
                    }
                }
            }
            if ($rule.destinations) {
                It "Dst contains less than $SrcDstFieldObjectLimit objects." {
                    ($rule.destinations.destination | Measure-Object).count | Should -BeLessOrEqual $SrcDstFieldObjectLimit
                }
                foreach ($destination in $rule.destinations.destination) {
                    It "Dst contains only objects supported by NSX-T: $($destination.type) - $($destination.name) ($($destination.value))" {
                        $destination.type | Should -BeIn $eligibleForMigrationSrcDst
                    }
                }
            }
            if ($rule.appliedToList) {
                It "Applied To contains less than $AppliedToFieldObjectLimit objects." {
                    ($rule.appliedToList.appliedTo | Measure-Object).count | Should -BeLessOrEqual $AppliedToFieldObjectLimit
                }
                foreach ($appliedTo in $rule.appliedToList.appliedTo) {
                    It "AppliedToContains only objects supported by NSX-T: $($appliedTo.type) - $($appliedTo.name) ($($appliedTo.value))" {
                        $appliedTo.type | Should -BeIn $eligibleForMigrationAppliedTo
                    }
                }
            }
        }
    }

    foreach ($rule in ($DfwConfigExportXML.firewallConfiguration.layer3RedirectSections.section.rule | Where-Object { $_ -ne $null })) {
        $pesterDisplayName = "RuleId: $($rule.id)"
        if ($rule | Get-Member -MemberType Property -Name name) {
            $pesterDisplayName = "$pesterDisplayName - $($Rule.name)"
        }

        Context "DFW($testVersion): Configuration - Layer3RedirectSections: $pesterDisplayName" {
            if ($rule.sources) {
                It "Src contains less than $SrcDstFieldObjectLimit objects." {
                    ($rule.sources.source | Measure-Object).count | Should -BeLessOrEqual $SrcDstFieldObjectLimit
                }

                foreach ($source in $rule.sources.source) {
                    It "Src contains only objects supported by NSX-T: $($source.type) - $($source.name) ($($source.value))" {
                        $source.type | Should -BeIn $eligibleForMigrationSrcDst
                    }
                }
            }
            if ($rule.destinations) {
                It "Dst contains less than $SrcDstFieldObjectLimit objects." {
                    ($rule.destinations.destination | Measure-Object).count | Should -BeLessOrEqual $SrcDstFieldObjectLimit
                }
                foreach ($destination in $rule.destinations.destination) {
                    It "Dst contains only objects supported by NSX-T: $($destination.type) - $($destination.name) ($($destination.value))" {
                        $destination.type | Should -BeIn $eligibleForMigrationSrcDst
                    }
                }
            }
        }
    }
}
