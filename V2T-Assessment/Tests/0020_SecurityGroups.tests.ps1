$testVersion = "v1.0.1"

Describe "SecurityGroups" {
    BeforeAll {
        $capturehash = $SecurityGroupCaptureHash
        $eligibleForMigration = 'IPSet', 'SecurityGroup', 'SecurityTag', 'MACSet', 'VirtualWire'
        Write-Host "  --> Executing Security Group tests for $TargetVersion"

        $configMaxVer23 = @{
            "MaxSecurityGroups"             = 10000
            "MaxSecurityGroupStaticMembers" = 500
            "eligibleForMigration"          = 'IPSet', 'SecurityGroup', 'SecurityTag', 'MACSet', 'VirtualWire'
        }

        $configMaxVer24 = @{
            "MaxSecurityGroups"             = 10000
            "MaxSecurityGroupStaticMembers" = 500
            "eligibleForMigration"          = 'IPSet', 'SecurityGroup', 'SecurityTag', 'MACSet', 'VirtualWire', 'DistributedVirtualPortgroup', 'VirtualMachine'
        }
        $configMaxHash = @{
            "3.0" = $configMaxVer24
            "2.4" = $configMaxVer24
            "2.3" = $configMaxVer23
        }

        $dynamicSetLimit = 5
        $dynamicSetCriteriaLimit = 5

    }

    AfterAll {
        Remove-Variable -Name CaptureHash
    }

    Context "SecurityGroups($testVersion): NSX-T Configuration Maximums" {
        It "Total number of Security Groups less than $($configMaxHash[$TargetVersion]['MaxSecurityGroups'])" {
            ($capturehash.keys | Measure-Object).count | Should -Not -BeGreaterThan $configMaxHash[$TargetVersion]['MaxSecurityGroups']
        }
    }

    foreach ($key in $capturehash.keys) {
        [xml]$xml = $capturehash.item($key)
        $item = $xml.securitygroup
        $pesterDisplayName = "$($item.name)($($item.objectid))"
        Context "SecurityGroups($testVersion): Configuration: $($pesterDisplayName)" {

            It "Contains no exclude member configuration." {
                ($item.excludemember | Measure-Object).count | Should -Not -BeGreaterThan 0
            }

            It "Contains no more than $($configMaxHash[$TargetVersion]['MaxSecurityGroupStaticMembers']) static members" {
                ($item.member | Measure-Object).count | Should -Not -BeGreaterThan $configMaxHash[$TargetVersion]['MaxSecurityGroupStaticMembers']
            }

            foreach ($includeMember in $item.member) {
                It "Contains only member objects supported by NSX-T $TargetVersion : $($includeMember.objectTypeName) - $($includeMember.name) ($($includeMember.objectId))" {
                    $includeMember.objectTypeName | Should -BeIn $configMaxHash[$TargetVersion]['eligibleForMigration']
                }
            }

            if ($item.dynamicMemberDefinition) {
                It "Contains no more than $dynamicSetLimit dynamic sets" {
                    ($item.dynamicMemberDefinition.dynamicSet | Measure-Object).count | Should -BeLessOrEqual $dynamicSetLimit
                }

                foreach ($set in $item.dynamicMemberDefinition.dynamicSet) {
                    It "Dynamic set Contains no more than $dynamicSetCriteriaLimit dynamicCriteria" {
                        ($set.dynamicCriteria | Measure-Object).count | Should -BeLessOrEqual $dynamicSetCriteriaLimit
                    }

                    if ( (($set.dynamicCriteria.operator | Select-Object -Unique) -eq "AND") -AND (($set.dynamicCriteria | Measure-Object).count -gt 1) ) {
                        It "Dynamic set with AND operator contains multiple criteria of same type: $(($set.dynamicCriteria.key | Select-Object -Unique | Sort-Object) -join ',')" {
                            ($set.dynamicCriteria.key | Select-Object -Unique | Measure-Object).count | Should -BeLessOrEqual 1 -Because "NSX-T dynamic criteria only allows multiple criteria if they are of the same type"
                        }
                    }
                }

                ################################################################################

                if ( ( ($item.dynamicMemberDefinition.dynamicSet | Measure-Object).count -gt 1) -AND ($item.dynamicMemberDefinition.dynamicSet.operator -eq "AND") ) {
                    # Check to cater for the situation which produces the
                    # following NSX-T Error message: To use AND
                    # operator, the main criteria should have the same resource
                    # type and no nested criteria should be available
                    $mainSetCriteriaTypes = New-Object System.Collections.ArrayList
                    foreach ($criteria in $item.dynamicMemberDefinition.dynamicSet[0].dynamicCriteria) {
                        if ($criteria.key -eq "ENTITY") {
                            # $entityMappedItem = $entityMap.item(($criteria.value -split ('-'))[0])
                            # if (! $entityMappedItem) {
                            #     Throw "Unhandled entity belongs to type: $($criteria.value)"
                            # }
                            $mainSetCriteriaTypes.Add($criteria.object.objectTypeName)
                        }
                        else {
                            $mainSetCriteriaTypes.Add($criteria.key)
                        }
                    }
        
                    foreach ($set in $item.dynamicMemberDefinition.dynamicSet | Select-Object -SkipIndex 0 ) {
                        $childSetCriteriaTypes = New-Object System.Collections.ArrayList
                        foreach ($criteria in $set.dynamicCriteria) {
                            if ($criteria.key -eq "ENTITY") {
                                # $entityMappedItem = $entityMap.item(($criteria.value -split ('-'))[0])
                                # if (! $entityMappedItem) {
                                #     Throw "Unhandled entity belongs to type: $($criteria.value)"
                                # }
                                $childSetCriteriaTypes.Add($criteria.object.objectTypeName)
                            }
                            else {
                                $childSetCriteriaTypes.Add($criteria.key)
                            }
        
                        }
                        It "Contains multiple dynamic sets using AND operator. Criteria type of child dynamic criterias ($($childSetCriteriaTypes -join (','))) should match that of the main criteria ($($mainSetCriteriaTypes -join (',')))" {
                            # The following comparison just does a string match, and outputs either True or False as a string.
                            $compareCriteriaTypes = $($childSetCriteriaTypes -join (',') -eq $mainSetCriteriaTypes -join (',')) 
                            # Convert the string to a boolean for easy comparison.
                            [System.Convert]::ToBoolean($compareCriteriaTypes) | Should -BeTrue -Because "I said So"
                        }
                    }
                }
                ################################################################################  
                
                foreach ($dynamicCriteria in $item.dynamicMemberDefinition.dynamicSet.dynamicCriteria) {
                    It "Dynamic criteria expression does not use regex." {
                        $dynamicCriteria.criteria | Should -Not -Be "similar_to" -Because "Regex expressions are not supported in NSX-T"
                    }
                }
                ################################################################################  
            }
        }
    }
}