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

function Run-Command([scriptblock]$Command, [switch]$Fatal, [switch]$Quiet) {
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
    Run-Command -Quiet { & $git fetch }

    Write-Output "Verifying $sha..."
    $sha = & $git rev-parse $sha
    if ($LASTEXITCODE -ne 0) {
        write-host -foregroundcolor red "Error: invalid SHA. USAGE: $self <SHA>"
        popd
        break
    }

    Write-Output "Checking out $sha..."
    Run-Command -Quiet -Fatal { & $git checkout $sha }

    Pop-Location

    if (![string]::IsNullOrEmpty($libgit2Name)) {
        $binaryFilename = $libgit2Name
    } else {
        $binaryFilename = "git2-" + $sha.Substring(0,7)
    }

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\contentFiles\any\any\libgit2_hash.txt") $sha
    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\contentFiles\any\any\libgit2_filename.txt") $binaryFilename

    $buildProperties = @"
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <ItemGroup>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x64\native\$binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x64\native\$binaryFilename.dll">
            <Link>lib\win32\x64\$binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x64\native\$binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x64\native\$binaryFilename.pdb">
            <Link>lib\win32\x64\$binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x86\native\$binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x86\native\$binaryFilename.dll">
            <Link>lib\win32\x86\$binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x86\native\$binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\win7-x86\native\$binaryFilename.pdb">
            <Link>lib\win32\x86\$binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\osx\native\lib$binaryFilename.dylib')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\osx\native\lib$binaryFilename.dylib">
            <Link>lib\osx\lib$binaryFilename.dylib</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\..\runtimes\linux-x64\native\lib$binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\..\runtimes\linux-x64\native\lib$binaryFilename.so">
            <Link>lib\linux\x86_64\lib$binaryFilename.so</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Include="`$(MSBuildThisFileDirectory)\..\..\libgit2\LibGit2Sharp.dll.config">
            <Link>LibGit2Sharp.dll.config</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
    </ItemGroup>
</Project>
"@

    sc -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\net40\LibGit2Sharp.NativeBinaries.props") $buildProperties

    $dllConfig = @"
<configuration>
    <dllmap os="linux" cpu="x86-64" wordsize="64" dll="$binaryFilename" target="lib/linux/x86_64/lib$binaryFilename.so" />
    <dllmap os="osx" cpu="x86,x86-64" dll="$binaryFilename" target="lib/osx/lib$binaryFilename.dylib" />
</configuration>
"@

    sc -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\libgit2\LibGit2Sharp.dll.config") $dllConfig

    Write-Output "Done!"
}
exit
