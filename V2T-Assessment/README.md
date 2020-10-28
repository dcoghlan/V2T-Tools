# V2T

Repository to store tools and artifacts related to V2T Migrations.

## V2T Assessment

A quick Powershell script which takes a PowerNSX Capture Bundle as input and uses the Pester testing framework to run a series of tests against the configuration.

The script is designed to provide assistance when looking at a NSX-v configuration to find the needles in the haystack that might cause headaches when trying to to a manual/scripted migration.

The tests implemented in this script, are not a complete list of everything that will or won't work in a V2T migration. The source of truth, is and always will be the NSX-T documentation on the VMware website:

- [https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html)

## Contributing

If you find that you have a scenario that is not handled in the current tests, there are 2 ways to get tests added.

1. Fork the repository, write the tests, and submit a pull request. Please give detailed example of why the test is needed, and how it can be detected in the current configuration files in the object capture bundle.
2. Raise an issue and provide as much details as possible. Due to limited access to lab environments to re-create your specific configuration, it is easier to work against your actual capture bundle, but for obvious reasons, I don't really want you to upload them to this public repository. Please make it available to myself through a private repository, or reach out to me via email [dcoghlan@vmware.com](mailto://dcoghlan@vmware.com) and we will see how you can provide this to me securely. This option will take longer and turn-around time will depend on my current workload.

## Prerequisites

### Powershell

The minimum version of Powershell required is 5.1

### Pester

The scripts requires Pester to run. However, the latest versions of Pester (5.x) are not supported with this script. To install a known working version of Pester from the Powershell Gallery, use the following command

```Powershell
Install-Module -Name Pester -RequiredVersion 4.4.3
```

### PowerNSX Object Capture Bundle

[PowerNSX](https://powernsx.github.io/) has script which will grab a whole heap of topology information and DFW configuration from your environment and bundle it up into a zip fie. We can use this file to create a Visio topology diagram of the environment and to take a look over the configuration of the firewall rules to make sure they can be configured in NSX-T easily.

#### Instructions

- Download the file `NsxObjectCapture.ps1` from the `/tools/DiagramNSX/` folder in the VMware [PowerNSX Github Repo](https://github.com/vmware/powernsx).
- Connect to the NSX Manager and vCenter using PowerNSX/PowerCLI
- Run the script to generate the object capture bundle.

### How to run

> _By default, the output will be stored in the home directory of the user currently running the command. The system defined variable `$home` will show where the output will be saved_.

#### Example 1

- CaptureBundle for LabCorp. The test output is not displayed on the console.

```None
./V2TAssessment.ps1 -CaptureBundle /Path/To/PowerNSX/CaptureBundle/NSX-ObjectCapture-10.250.8.12-2018_12_17_08_47_55.zip -NamePrefix LabCorp
```

#### Example 2

- CaptureBundle for LabCorp. Only Pester Failed tests will be displayed on the console (along with Describe context).

```None
./V2TAssessment.ps1 -CaptureBundle /Path/To/PowerNSX/CaptureBundle/NSX-ObjectCapture-10.250.8.12-2018_12_17_08_47_55.zip -NamePrefix LabCorp -show fails
```

#### Example 3

- CaptureBundle for LabCorp. All Pester tests will be displayed on the console.

```None
./V2TAssessment.ps1 -CaptureBundle /Path/To/PowerNSX/CaptureBundle/NSX-ObjectCapture-10.250.8.12-2018_12_17_08_47_55.zip -NamePrefix LabCorp -show All
```

#### Example 4

- CaptureBundle for LabCorp. Only execute specific Pester tests (Describe block containing text). In this example its the tests defined in the file `./Tests/0020_SecurityGroups.tests.ps1`.

```None
./V2TAssessment.ps1 -CaptureBundle /Path/To/PowerNSX/CaptureBundle/NSX-ObjectCapture-10.250.8.12-2018_12_17_08_47_55.zip -NamePrefix LabCorp -TestName "SecurityGroups" -Show All
```

#### Example 5

- To specify a custom output directory

```None
./V2TAssessment.ps1 -CaptureBundle /Path/To/PowerNSX/CaptureBundle/NSX-ObjectCapture-10.250.8.12-2018_12_17_08_47_55.zip -NamePrefix LabCorp -OutputDir /path/to/outputdir/
```

## Output Files

The script will create the output files in the OutputDir if specified. If no OutputDir is specified, the users home directory will be used as the OutputDir.

Within the OutputDir, a folder named the same as the capture bundle will be created so that multiple capture budles can be processed with the same name prefix.

Within the folder named the same as the capture bundle, it will create 3 folders:

- CaptureBundle : Used to store a copy of the actual capture bundle that the tests were run against.
- Extracted : The extracted files from the capture bundle. This helps if you want to take a look at the raw files.
- Reports: The actual test results are stored in this folder
  - `<capture bundle name>.xml` : Raw Pester test results
  - `<namePrefix>_test_results_all.html`: HTMl file showing all the tests and their results. This is often quite a large file.
  - `<namePrefix>_test_results_failures_only.html`: HTMl file showing only the test failure results. This is generally the most useful file as you generally just want to know what issue the script has picked up.

## Console Output Example

```None
PS > ./V2TAssessment.ps1 -CaptureBundle '/some/path/NSX-ObjectCapture-LabCorp-2020_04_28_10_13_20.zip' -Name LabCorp
  --> Creating folder: /Users/JohnDoe/V2TAssessment/LabCorp/NSX-ObjectCapture-LabCorp-2020_04_28_10_13_20/Extracted/
  --> Creating folder: /Users/JohnDoe/V2TAssessment/LabCorp/NSX-ObjectCapture-LabCorp-2020_04_28_10_13_20/Reports/
  --> Creating folder: /Users/JohnDoe/V2TAssessment/LabCorp/NSX-ObjectCapture-LabCorp-2020_04_28_10_13_20/CaptureBundle/
  --> Extracting files from capture bundle...
  --> Loading XML data from extracted capture bundle files...
  --> Starting Pester tests...
  --> Executing IP Set tests for 3.0
  --> Executing Security Group tests for 3.0
  --> Executing SecurityTag tests for 3.0
  --> Executing DFW tests for 3.0
  --> Executing Edge tests for 3.0

TagFilter         :
ExcludeTagFilter  :
TestNameFilter    :
TotalCount        : 70366
PassedCount       : 69050
FailedCount       : 1316
SkippedCount      : 0
PendingCount      : 0
InconclusiveCount : 0
Time              : 00:25:51.2439234
TestResult        : {@{Parameters=System.Collections.Specialized.OrderedDictionary; Passed=True; Result=Passed; ParameterizedSuiteName=; Context=IPSets(v1.0.0): NSX-T Configuration Maximums; ErrorRecord=; Show=None; StackTrace=; Time=00:00:00.3659842; Describe=IPSets; FailureMessage=;
                    Name=Total number of IP Sets is less than 10000}, @{Parameters=System.Collections.Specialized.OrderedDictionary; Passed=True; Result=Passed; ParameterizedSuiteName=; Context=IPSets(v1.0.0): PH-10.206.179.239-32(ipset-609); ErrorRecord=; Show=None; StackTrace=;
                    Time=00:00:00.1132632; Describe=IPSets; FailureMessage=; Name=IP Set must contain at least 1 entry: PH-10.206.179.239-32(ipset-609)}, @{Parameters=System.Collections.Specialized.OrderedDictionary; Passed=True; Result=Passed; ParameterizedSuiteName=;
                    Context=IPSets(v1.0.0): PH-10.206.179.239-32(ipset-609); ErrorRecord=; Show=None; StackTrace=; Time=00:00:00.0344367; Describe=IPSets; FailureMessage=; Name=IP Set contains no more than 4000 entries: PH-10.206.179.239-32(ipset-609)},
                    @{Parameters=System.Collections.Specialized.OrderedDictionary; Passed=True; Result=Passed; ParameterizedSuiteName=; Context=IPSets(v1.0.0): PH-10.206.179.239-32(ipset-609); ErrorRecord=; Show=None; StackTrace=; Time=00:00:00.0067103; Describe=IPSets; FailureMessage=;
                    Name=IP Set contains no more than 500 entries (Policy Group static members): PH-10.206.179.239-32(ipset-609)}…}


  --> Reports saved to: /Users/JohnDoe/V2TAssessment/LabCorp/NSX-ObjectCapture-LabCorp-2020_04_28_10_13_20/Reports/

PS >
```
