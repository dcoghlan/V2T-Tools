Param (

    [parameter ( Mandatory = $true, Position = 1 )]
    [ValidateScript ( { if ( -not ( Test-Path $_ )) { throw "CaptureBundle $_ not found." } else { $true } })]
    [string]$CaptureBundle,
    [parameter ( Mandatory = $false, Position = 2 )]
    [ValidateScript ( { if ( -not (Test-Path $_) ) { throw "OutputDir $_ not found." } else { $true } })]
    [string]$OutputDir = $home,
    [parameter ( Mandatory = $true)]
    [string]$NamePrefix,
    [parameter ( Mandatory = $False)]
    [ValidateSet("None", "Default", "Passed", "Failed", "Pending", "Skipped", 
        "Inconclusive", "Describe", "Context", "Summary", "Header", "All", 
        "Fails", IgnoreCase = $True)]
    [string]$Show = "None",
    [parameter ( Mandatory = $False)]
    [ValidateSet("IPSets", "SecurityGroups", "DFW", "SecurityTags", "Edge" IgnoreCase = $True)]
    [string]$TestName,
    [parameter ( Mandatory = $False)]
    [ValidateSet("1.0", "2.3", "2.4", "2.5", "3.0", IgnoreCase = $True)]
    [string]$TargetVersion = "3.0"
    
)

# Used within all the test for when a test should be skipped or not based on the
# minimum version required.
function Invoke-RequiredVersionCheck {
    param (
        [version]$required,
        [version]$TargetVersion
    )
    if ($TargetVersion -ge $required) {
        return $False
    }
    else {
        return $True
    }
}

# There is some stuff in this script which needs a minimum version of powershell
#REQUIRES -version 5.1
#REQUIRES -Modules @{ModuleName="Pester";ModuleVersion="4.4.3";MaximumVersion="4.9.9.9"}

# Make sure Pester is installed and loaded. If not, then install from gallery.
# Pretty sure I don't need this as it gets handled by the requires line above.
if (! (Get-Module -Name Pester -ListAvailable) ) {
    Write-Host "  --> Pester not found. Attempting to download from Gallery..."
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name Pester -RequiredVersion 4.4.3
    Import-Module -Name Pester -MinimumVersion 4.4.3 -MaximumVersion 4.9.9.9 -ErrorAction Stop
}
elseif (! (Get-Module -Name Pester) ) {
    Write-Host "  --> Pester not loaded. Importing module"
    Import-Module -Name Pester -MinimumVersion 4.4.3 -MaximumVersion 4.9.9.9 -ErrorAction Stop
}

# Abstract object for the path separator for multi-os support
$pathSeparator = [IO.Path]::DirectorySeparatorChar

# Use the name of the capture bundle to create a folder to store the artifacts.
$ExtractDirName = [io.path]::GetFileNameWithoutExtension($CaptureBundle)

# List of folder names to create for each NamePrefix/Customer
$OutputFolders = @("Extracted", "Reports", "CaptureBundle")

# Name of the script will be used to create a folder structure for any atrifacts
$myFileName = [io.path]::GetFileNameWithoutExtension($MyInvocation.InvocationName)

# Location of the Pester Tests to execute.
$PesterTestsRoot = "$PSScriptRoot/Tests"

# If the output folders already exists and has files in it, clean them up before
# extraction, otherwise if they don't exist, then create them
foreach ($Name in $OutputFolders) {
    $path = "$OutputDir$($pathSeparator)$myFileName$($pathSeparator)$NamePrefix$($pathSeparator)$ExtractDirName$($pathSeparator)$Name$($pathSeparator)"
    if ( Test-Path $path ) {
        $directoryInfo = Get-ChildItem $path* | Measure-Object
        if ( $directoryInfo.count -ge 1 ) {
            Write-Host "  --> Removing existing files in folder: $Path"
            Remove-Item "$path*"
        }
    }
    elseif (! ( Test-Path $path )) {
        Write-Host "  --> Creating folder: $path"
        New-Item -Type Directory $path | Out-Null
    }
    New-Variable -Name "$($Name)Folder" -Value $Path
}

# Take a copy of the CaptureBundle and store it in the captureBundleFolder
# This is so it easier to keep track of which outputs were created from which
# capture bundle. It gets very confusing when working with many different ones
# from differing customers, or even the same customer, as often there is no
# identifiable names etc in the filenames, only ip addresses sometimes.
Copy-Item -Path $CaptureBundle -Destination $CaptureBundleFolder -Force

# Extract the zip file. Theres differences between Powershell Desktop and Core,
# hence this piece of code.
try {
    Write-Host "  --> Extracting files from capture bundle..."

    #Desktop extract to zip
    if ($psversiontable.PSEdition -ne "Core") {
        Add-Type -assembly "system.io.compression.filesystem"
    }
    [system.io.compression.zipfile]::ExtractToDirectory($CaptureBundle, $ExtractedFolder)

}
catch {
    Throw "Unable to extract capture bundle. $_"
}

# Load the XML files which were extracted from the capture bundle.
Write-Host "  --> Loading XML data from extracted capture bundle files..."

$IpSetExportFile = "$ExtractedFolder/IpSetExport.xml"
$MacAddressExportFile = "$ExtractedFolder/MacExport.xml"
$DfwConfigExport = "$ExtractedFolder/DfwConfigExport.xml"
$SecurityGroupExportFile = "$ExtractedFolder/SecurityGroupExport.xml"
$SecurityTagExportFile = "$ExtractedFolder/SecurityTagExport.xml"
$ServicesExportFile = "$ExtractedFolder/ServicesExport.xml"
$ServiceGroupExportFile = "$ExtractedFolder/ServiceGroupExport.xml"
$ServiceComposerPoliciesExportFile = "$ExtractedFolder/SecPolExport.xml"
$EdgeExportFile = "$ExtractedFolder/EdgeExport.xml"
$LogicalRouterExportFile = "$ExtractedFolder/LrExport.xml"
$LogicalSwitchExportFile = "$ExtractedFolder/LsExport.xml"



try {
    $IpSetCaptureHash = Import-Clixml $IpSetExportFile
    $MacAddressCaptureHash = Import-Clixml $MacAddressExportFile
    $SecurityGroupCaptureHash = Import-Clixml $SecurityGroupExportFile
    $SecurityTagCaptureHash = Import-Clixml $SecurityTagExportFile
    $ServicesCaptureHash = Import-Clixml $ServicesExportFile
    $ServiceGroupCaptureHash = Import-Clixml $ServiceGroupExportFile
    [System.Xml.XmlDocument]$DfwConfigExportXML = Get-Content -Path $DfwConfigExport
    $ServiceComposerPoliciesCaptureHash = Import-Clixml $ServiceComposerPoliciesExportFile
    $EdgeCaptureHash = Import-Clixml $EdgeExportFile
    $LogicalRouterHash = Import-Clixml $LogicalRouterExportFile
    $LogicalSwitchHash = Import-Clixml $LogicalSwitchExportFile
}
catch {

    Throw "Unable to import capture bundle content.  Is this a valid capture bundle? $_"

}

# Generate the parameters for Invoking Pester and then do the needful
Write-Host "  --> Starting Pester tests..."
$pesterSplat = @{
    "PassThru"     = $True
    "OutputFile"   = "$($ReportsFolder)$ExtractDirName.xml"
    "OutputFormat" = "NUnitXML"
    "Show"         = $Show
    "script"       = $PesterTestsRoot
}

if ($TestName) { $pesterSplat.Add("TestName", $TestName) }

# Doing the needful
$test = Invoke-Pester @pesterSplat

$date = Get-Date
# Embedding a bit of CSS into the file so that the HTML output is self contained.
$head = @"
<style>
table,
th,
td {
  border: 1px solid black;
  border-collapse: collapse;
  font-family: Verdana, Geneva, sans-serif;
}

th,
td {
  padding: 5px;
}

tr:nth-child(even) {
  background: #e9e9ff;
}

p,
h2,
h3 {
  font-family: Verdana, Geneva, sans-serif;
}

</style>

"@
$htmlOptionsDetailedReport = @{
    "Title" = $namePrefix;
    "Body"  = "<h2>V2T Assessment Report: Detailed</h2>";
    "Head"  = $head;
    "pre"   = "Total: $($test.TotalCount)<br>Passed: $($test.PassedCount)<br>Failed: $($test.FailedCount)"
    "post"  = "<h3>Generated By: VMware Customer Success<br>Created on: $($date)<br> Created from: $(Split-Path -Leaf $CaptureBundle).<br>Duration: $($test.time)</h3>";
    # TODO: Create parameter to toggle this.
    # "CssUri" = "V2T.css"
}

function New-HtmlReport {

    Param (
        [parameter ( Mandatory = $False)]
        [switch]$FailuresOnly = $False,
        [parameter ( Mandatory = $True)]
        [object[]]$Results,
        [parameter ( Mandatory = $True)]
        [object]$HtmlOptions,    
        [parameter ( Mandatory = $True)]
        [object]$HtmlOutputFile
    )
    
    if ($FailuresOnly) {
        $rawHTML = $Results | Where-Object { $_.result -ne "passed" } | Select-Object Describe, Context, result, name, errorRecord | ConvertTo-Html @HtmlOptions 
    }
    else {
        $rawHTML = $Results | Select-Object Describe, Context, result, name, errorRecord | ConvertTo-Html @HtmlOptions 
    }    
    # Hack to Color code the results cell 
    $rawHTML | ForEach-Object { if ($_ -like "*<td>Passed</td>*") { $_ -replace "<td>Passed</td>", "<td bgcolor=green>Passed</td>" }elseif ($_ -like "*<td>Failed</td>*") { $_ -replace "<td>Failed</td>", "<td bgcolor=red>Failed</td>" }else { $_ } } | Set-Content $HtmlOutputFile

}

# Create HTML output file based on results returned from Pester.
New-HtmlReport -Results $Test.TestResult -HtmlOptions $htmlOptionsDetailedReport -HtmlOutputFile "$($ReportsFolder)$($NamePrefix)_test_results_failures_only.html" -FailuresOnly
New-HtmlReport -Results $Test.TestResult -HtmlOptions $htmlOptionsDetailedReport -HtmlOutputFile "$($ReportsFolder)$($NamePrefix)_test_results_all.html"

# Display the returned Pester test results object to the screen.
$test
Write-Host "`n  --> Reports saved to: $ReportsFolder"
