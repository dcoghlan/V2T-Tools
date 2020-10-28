# Version of the test. This is here so that it can be included in the HTML
# output and it can be seen which version of the test was used.
$testVersion = "v1.0.0"

# Describe block is used to desctibe the name of the test objects. The name of
# the describe block is also what the tests are referred to when running
# selective tests.

Describe "Things" {

    BeforeAll {
        # BeforeAll block runs _once_ at invocation regardless of number of
        # tests/contexts/describes.

        # Load the required files from the capture bundle
        $CaptureHash = $SecurityGroupCaptureHash

        # Put any other items in here that are required to be run before the
        # tests are executed.
        $configMax = 10000

    }

    AfterAll {
        # AfterAll block runs _once_ at completion of invocation regardless of
        # number of tests/contexts/describes. Clean up anything you create in
        # here. Be forceful - you want to leave the test env as you found it as
        # much as is possible.

        # Remove the variables used to read the configuration
        Remove-Variable -Name CaptureHash
        Remove-Variable -Name configMax
    }

    # Add the required contexts here. A context is used to group similar type
    # tests together.
    Context "SecurityGroups($testVersion): NSX-T Configuration Maximums" {

        It "Thing is less than $configMax"
        $CaptureHash.count | Should -BeLessOrEqual $configMax

    }

    # Loop through the capturehash to process each objects configuration
    foreach ($key in $capturehash.keys) {
        [xml]$xml = $capturehash.item($key)
        $item = $xml.securitygroup
        $pesterDisplayName = "$($item.name)($($item.objectid))"
        Context "SecurityGroups($testVersion): Configuration: $($pesterDisplayName)" {
            # The variable TargetVersion is provided when the assessment script is
            # executed. The following test will only execute when the target version
            # is greaterthan or equal to the required version (e.g. 2.5.0)
            It "Can support object type" -Skip:$(RequiredVersionCheck -required "2.5.0" -TargetVersion $TargetVersion) {
                $($CaptureHash.item('securitygroup-1234')).objectTypeName | Should -Be "SecurityGroup"
            }
        }
    }
}