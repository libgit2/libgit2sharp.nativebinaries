<#
.SYNOPSIS
    Updates the libgit2 submodule to the specified commit and updates libgit2_hash.txt and NativeBinaries.props with the new hash value.
.PARAMETER sha
    Desired libgit2 version. This is run through `git rev-parse`, so branch names are okay too.
#>

Param(
    [string]$sha = 'HEAD'
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

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libgit2_hash.txt") $sha
    
    $binaryFilename = "git2-" + $sha.Substring(0,7)

    $buildProperties = @"
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <ItemGroup>
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\libgit2_hash.txt" />
    </ItemGroup>
    <ItemGroup Condition=" '`$(OS)' == 'Windows_NT' ">
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\windows\amd64\$binaryFilename.dll">
            <Link>NativeBinaries\amd64\$binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\windows\amd64\$binaryFilename.pdb">
            <Link>NativeBinaries\amd64\$binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\windows\x86\$binaryFilename.dll">
            <Link>NativeBinaries\x86\$binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\windows\x86\$binaryFilename.pdb">
            <Link>NativeBinaries\x86\$binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
    </ItemGroup>
    <ItemGroup Condition=" '`$(OS)' == 'Unix' And Exists('/Library/Frameworks') ">
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\osx\lib$binaryFilename.dylib">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
    </ItemGroup>
        <ItemGroup Condition=" '`$(OS)' == 'Unix' And !Exists('/Library/Frameworks') ">
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\linux\amd64\lib$binaryFilename.so">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
    </ItemGroup>
</Project>
"@

    sc -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\LibGit2Sharp.NativeBinaries.props") $buildProperties

    Write-Output "Done!"
}
exit
