<#
.SYNOPSIS
    Updates the libgit2 submodule to the specified commit and updates libgit2_hash.txt and NativeBinaries.props with the new hash value.
.PARAMETER sha
    Desired libgit2 version. This is run through `git rev-parse`, so branch names are okay too.
#>

Param(
    [string]$sha = 'HEAD',
    [string]$libgit2Name = ''
)

Set-StrictMode -Version Latest

$self = Split-Path -Leaf $MyInvocation.MyCommand.Path
$projectDirectory = Split-Path $MyInvocation.MyCommand.Path
$libgit2Directory = Join-Path $projectDirectory "libgit2"

function Invoke-Command([scriptblock]$Command, [switch]$Fatal, [switch]$Quiet) {
    $output = ""
    if ($Quiet) {
        $output = & $Command 2>&1
    } else {
        & $Command
    }

    if (!$Fatal) {
        return
    }

    $exitCode = 0
    if ($LastExitCode -ne 0) {
        $exitCode = $LastExitCode
    } elseif (!$?) {
        $exitCode = 1
    } else {
        return
    }

    $error = "``$Command`` failed"
    if ($output) {
        Write-Host -ForegroundColor yellow $output
        $error += ". See output above."
    }
    Throw $error
}

function Find-Git {
    $git = @(Get-Command git)[0] 2>$null
    if ($git) {
        $git = $git.Definition
        Write-Host -ForegroundColor Gray "Using git: $git"
        & $git --version | write-host -ForegroundColor Gray
        return $git
    }
    throw "Error: Can't find git"
}

Push-Location $libgit2Directory

& {
    trap {
        Pop-Location
        break
    }

    $git = Find-Git

    Write-Output "Fetching..."
    Invoke-Command -Quiet { & $git fetch }

    Write-Output "Verifying $sha..."
    $sha = & $git rev-parse $sha
    if ($LASTEXITCODE -ne 0) {
        write-host -foregroundcolor red "Error: invalid SHA. USAGE: $self <SHA>"
        Pop-Location
        break
    }

    Write-Output "Checking out $sha..."
    Invoke-Command -Quiet -Fatal { & $git checkout $sha }

    Pop-Location

    if (![string]::IsNullOrEmpty($libgit2Name)) {
        $binaryFilename = $libgit2Name
    } else {
        $binaryFilename = "git2-" + $sha.Substring(0,7)
    }

    Set-Content -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libgit2_hash.txt") $sha

    $buildProperties = @"
<Project>
  <PropertyGroup>
    <MSBuildAllProjects>`$(MSBuildAllProjects);`$(MSBuildThisFileFullPath)</MSBuildAllProjects>
    <libgit2_propsfile>`$(MSBuildThisFileFullPath)</libgit2_propsfile>
    <libgit2_hash>$sha</libgit2_hash>
    <libgit2_filename>$binaryFilename</libgit2_filename>
  </PropertyGroup>
</Project>
"@

    Set-Content -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\LibGit2Sharp.NativeBinaries.props") $buildProperties

    $net46BuildProperties = @"
<Project>
  <PropertyGroup>
    <MSBuildAllProjects>`$(MSBuildAllProjects);`$(MSBuildThisFileFullPath)</MSBuildAllProjects>
    <libgit2_propsfile>`$(MSBuildThisFileFullPath)</libgit2_propsfile>
    <libgit2_hash>$sha</libgit2_hash>
    <libgit2_filename>$binaryFilename</libgit2_filename>
  </PropertyGroup>
  <ItemGroup>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x64\native\$binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x64\native\$binaryFilename.dll">
      <TargetPath>lib\win32\x64\$binaryFilename.dll</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x64\native\$binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x64\native\$binaryFilename.pdb">
      <TargetPath>lib\win32\x64\$binaryFilename.pdb</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x86\native\$binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x86\native\$binaryFilename.dll">
      <TargetPath>lib\win32\x86\$binaryFilename.dll</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x86\native\$binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win-x86\native\$binaryFilename.pdb">
      <TargetPath>lib\win32\x86\$binaryFilename.pdb</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\osx\native\lib$binaryFilename.dylib')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\osx\native\lib$binaryFilename.dylib">
      <TargetPath>lib\osx\lib$binaryFilename.dylib</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\linux-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\linux-x64\native\lib$binaryFilename.so">
      <TargetPath>lib\linux-x64\lib$binaryFilename.so</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\ubuntu.18.04-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\ubuntu.18.04-x64\native\lib$binaryFilename.so">
      <TargetPath>lib\ubuntu.18.04-x64\lib$binaryFilename.so</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\rhel-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\rhel-x64\native\lib$binaryFilename.so">
      <TargetPath>lib\rhel-x64\lib$binaryFilename.so</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\fedora-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\fedora-x64\native\lib$binaryFilename.so">
      <TargetPath>lib\fedora-x64\lib$binaryFilename.so</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\debian.9-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\debian.9-x64\native\lib$binaryFilename.so">
      <TargetPath>lib\debian.9-x64\lib$binaryFilename.so</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\alpine-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\alpine-x64\native\lib$binaryFilename.so">
      <TargetPath>lib\alpine-x64\lib$binaryFilename.so</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
    <ContentWithTargetPath Include="`$(MSBuildThisFileDirectory)\..\..\libgit2\LibGit2Sharp.dll.config">
      <TargetPath>LibGit2Sharp.dll.config</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
  </ItemGroup>
</Project>
"@

    Set-Content -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\net46\LibGit2Sharp.NativeBinaries.props") $net46BuildProperties

    $dllConfig = @"
<configuration>
    <dllmap os="linux" cpu="x86-64" wordsize="64" dll="$binaryFilename" target="lib/linux-x64/lib$binaryFilename.so" />
    <dllmap os="osx" cpu="x86,x86-64" dll="$binaryFilename" target="lib/osx/lib$binaryFilename.dylib" />
</configuration>
"@

    Set-Content -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\libgit2\LibGit2Sharp.dll.config") $dllConfig

    Write-Output "Done!"
}
exit
