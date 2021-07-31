Param(
    [Parameter(Mandatory=$true)]
    [string]$version,
    [switch]$pre
)

$buildDate = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
$versionSuffix = ""
if ($pre.IsPresent) { $versionSuffix = "-pre$BuildDate" }

# Create nuget package + legacy symbol pack
# See: https://docs.microsoft.com/en-us/nuget/create-packages/symbol-packages
.\nuget.exe pack nuget.package\NativeBinaries.nuspec `
    -Symbols `
    -Version $version$versionSuffix `
    -NoPackageAnalysis
