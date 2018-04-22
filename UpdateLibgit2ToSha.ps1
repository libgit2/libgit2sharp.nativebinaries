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
  <ItemGroup>
    <libgit2_rid Include='"win-x64"' />
    <libgit2_rid Include='"win-x86"' />
    <libgit2_rid Include='"osx"' />
    <libgit2_rid Include='"linux-x64"' />
    <libgit2_rid Include='"rhel-x64"' />
    <libgit2_rid Include='"fedora-x64"' />
    <libgit2_rid Include='"debian.9-x64"' />
  </ItemGroup>
</Project>
"@

    Set-Content -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\LibGit2Sharp.NativeBinaries.props") $buildProperties

    $net461BuildProperties = @"
<Project>
  <Import Project="`$(MSBuildThisFileDirectory)\..\LibGit2Sharp.NativeBinaries.props" />
  <ItemGroup>
    <ContentWithTargetPath Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\**\*">
      <TargetPath>runtimes\%(RecursiveDir)\%(Filename)%(Extension)</TargetPath>
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </ContentWithTargetPath>
  </ItemGroup>
</Project>
"@

    Set-Content -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\net461\LibGit2Sharp.NativeBinaries.props") $net461BuildProperties

    Write-Output "Done!"
}
exit
