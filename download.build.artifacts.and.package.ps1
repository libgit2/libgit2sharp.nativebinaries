Param(
    [string]$ref = "master",
    [switch]$verbose = $False
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PSDefaultParameterValues['Invoke-RestMethod:SkipHeaderValidation'] = $true
$PSDefaultParameterValues['Invoke-WebRequest:SkipHeaderValidation'] = $true

function Invoke-RestMethod-Ex($url, $downloadLocation) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $irmParams = @{
    }

    Write-Host -ForegroundColor "White" "-> Get $url"

    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    if ($proxy) {
        $proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $proxyUri = $proxy.GetProxy("$url")

        if ("$proxyUri" -ne "$url") {
            $irmParams.Proxy = "$proxyUri"
            $irmParams.ProxyUseDefaultCredentials = $true
        }
    }

    if ($downloadLocation) {
        $irmParams.OutFile = "$downloadLocation"
    }

    $output = Invoke-RestMethod @irmParams -Method "Get" -Uri "$url"

    if ($verbose) {
        Write-Host -ForegroundColor "Gray" "output = $(ConvertTo-Json $output)"
    }

    return $output
}

function Extract-BuildIdentifier($statuses, $forContext) {

    $status = $statuses | where { $_.context -eq $forContext } | select -First 1

    if (($status -eq $null) -or ("success".CompareTo($status.state) -ne 0)) {
        throw "No successful status has been found for context `"$forContext`"."
    }

    $buildNumber = $status.target_url.Split("/")[-1]

    return $buildNumber
}

function Download-AppVeyor-Artifacts($statuses, $downloadLocation) {
    $prOrBranch = "branch"

    if ($ref.StartsWith("pull/")) {
        $prOrBranch = "pr"
    }

    $buildIdentifier = Extract-BuildIdentifier $statuses "continuous-integration/appveyor/$prOrBranch"

    Write-Host -ForegroundColor "Yellow" "Retrieving AppVeyor build `"$buildIdentifier`""
    $build = Invoke-RestMethod-Ex "https://ci.appveyor.com/api/projects/libgit2/libgit2sharp-nativebinaries/builds/$buildIdentifier"

    $jobId = $build.build.jobs[0].jobId

    Write-Host -ForegroundColor "Yellow" "Retrieving AppVeyor job `"$jobId`" artifacts"
    $artifacts = Invoke-RestMethod-Ex "https://ci.appveyor.com/api/buildjobs/$jobId/artifacts"

    ForEach ($artifact in $artifacts) {
        $artifactFileName = $artifacts[0].fileName
        $localArtifactPath = "$downloadLocation\$artifactFileName"

        Write-Host -ForegroundColor "Yellow" "Downloading `"$artifactFileName`""
        Invoke-RestMethod-Ex "https://ci.appveyor.com/api/buildjobs/$jobId/artifacts/$artifactFileName" $localArtifactPath
    }
}

function Download-Travis-Artifacts($statuses, $downloadLocation) {
    $prOrBranch = "push"

    if ($ref.StartsWith("pull/")) {
        $prOrBranch = "pr"
    }

    $buildIdentifier = Extract-BuildIdentifier $statuses "continuous-integration/travis-ci/$prOrBranch"

    Write-Host -ForegroundColor "Yellow" "Retrieving Travis build `"$buildIdentifier`""
    $build = Invoke-RestMethod-Ex "https://api.travis-ci.org/builds/$buildIdentifier"

    $buildNumber = $build.number

    Write-Host -ForegroundColor "Yellow" "Retrieving Bintray version `"$buildNumber`" artifact list"
    $files = Invoke-RestMethod-Ex "https://api.bintray.com/packages/libgit2/compiled-binaries/libgit2/versions/$buildNumber/files"

    ForEach ($file in $files) {
        $artifactFileName = $file.name
        $localArtifactPath = "$downloadLocation\$artifactFileName"

        Write-Host -ForegroundColor "Yellow" "Downloading `"$artifactFileName`""
        Invoke-RestMethod-Ex "https://dl.bintray.com/libgit2/compiled-binaries/$artifactFileName" $localArtifactPath
    }
}

######################################################

$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$path = [System.IO.Path]::Combine($env:Temp, [System.IO.Path]::GetRandomFileName())
Write-Host -ForegroundColor "Yellow" "Creating temporary folder at `"$path`""
New-Item "$path" -type Directory > $null

if ($ref.StartsWith("pull/")) {
    $pr = $ref.Replace("pull/", "")
    Write-Host -ForegroundColor "Yellow" "Retrieving pull request information for pull request $pr"

    $prData = Invoke-RestMethod-Ex "https://api.github.com/repos/libgit2/libgit2sharp.nativebinaries/pulls/$pr"
    $statusesUrl = $prData.statuses_url
}
else {
    $statusesUrl = "https://api.github.com/repos/libgit2/libgit2sharp.nativebinaries/commits/$ref/statuses"
}

Write-Host -ForegroundColor "Yellow" "Retrieving LibGit2Sharp.NativeBinaries latest CI statuses of `"$ref`""
$statuses = Invoke-RestMethod-Ex $statusesUrl

Download-AppVeyor-Artifacts $statuses $path
Download-Travis-Artifacts $statuses $path

Write-Host -ForegroundColor "Yellow" "Build artifacts have been downloaded at `"$path`""

$package = Get-ChildItem -Path $path -Filter "*.nupkg"
$binaries = Get-ChildItem -Path $path -Filter "*.zip"

Write-Host -ForegroundColor "Yellow" "Extracting build artifacts"
Add-Type -assembly "System.IO.Compression.Filesystem"
[IO.Compression.ZipFile]::ExtractToDirectory("$($package.FullName)", "$($package.FullName).ext")

ForEach ($binary in $binaries) {
    [IO.Compression.ZipFile]::ExtractToDirectory("$($binary.FullName)", "$($package.FullName).ext")
}

Write-Host -ForegroundColor "Yellow" "Building final NuGet package"
Push-location "$($package.FullName).ext"
Remove-Item -Path ".\_rels\" -Recurse
Remove-Item -Path ".\package\" -Recurse
Remove-Item -Path '.\`[Content_Types`].xml'
& "$root/Nuget.exe" pack "LibGit2Sharp.NativeBinaries.NoTLS.nuspec" -OutputDirectory "$path" -NoPackageAnalysis -Verbosity "detailed"

$newPackage = Get-ChildItem -Path $path -Filter "*.nupkg"
Pop-Location

Write-Host -ForegroundColor "Yellow" "Copying package `"$($newPackage.Name)`" to `"$root`""

Move-Item -Path "$($newPackage.FullName)" -Destination "$root\$($newPackage.Name)"

Write-Host -ForegroundColor "Yellow" "Removing temporary folder"
Remove-Item "$path" -Recurse
