<#
.SYNOPSIS
    Updates the libgit2 submodule to the specified commit and updates libgit2_hash.txt and NativeBinaries.props with the new hash value.
.PARAMETER libgit2sha
    Desired libgit2 version. This is run through `git rev-parse`, so branch names are okay too.
.PARAMETER libssh2sha
    Desired libssh2 version. This is run through `git rev-parse`, so branch names are okay too.
.PARAMETER zlibsha
    Desired zlib version. This is run through `git rev-parse`, so branch names are okay too.
#>

Param(
    [string]$libgit2sha = 'HEAD',
    [string]$libgit2Name = '',
	[string]$libssh2sha = 'HEAD',
    [string]$libssh2Name = 'libssh2',
	[string]$zlibsha = 'HEAD',
    [string]$zlibName = 'zlib'
)

Set-StrictMode -Version Latest

$self = Split-Path -Leaf $MyInvocation.MyCommand.Path
$projectDirectory = Split-Path $MyInvocation.MyCommand.Path

$libgit2Directory = Join-Path $projectDirectory "libgit2"
$libssh2Directory = Join-Path $projectDirectory "libssh2"
$zlibDirectory = Join-Path $projectDirectory "zlib"

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

function Update-Lib($git, $lib, $directory, [ref]$sha) {
	Push-Location $directory

    Write-Output "$lib -> Fetching..."
    Run-Command -Quiet { & $git fetch }

    Write-Output "$lib -> Verifying $($sha.value)..."
    $sha.value = & $git rev-parse $sha.value
    if ($LASTEXITCODE -ne 0) {
        write-host -foregroundcolor red "Error: invalid SHA. USAGE: $self <SHA>"
        popd
        break
    }

    Write-Output "$lib -> Checking out $($sha.value)..."
    Run-Command -Quiet -Fatal { & $git checkout $sha.value }

    Pop-Location
}

Push-Location $libgit2Directory

& {
    trap {
        Pop-Location
        break
    }

    $git = Find-Git
	
	Update-Lib $git "libgit2" $libgit2Directory ([ref]$libgit2sha)
	Update-Lib $git "libssh2" $libssh2Directory ([ref]$libssh2sha)
	Update-Lib $git "zlib" $zlibDirectory ([ref]$zlibsha)

    #Write-Output "Fetching..."
    #Run-Command -Quiet { & $git fetch }

    #Write-Output "Verifying $libgit2sha..."
    #$libgit2sha = & $git rev-parse $libgit2sha
    #if ($LASTEXITCODE -ne 0) {
    #    write-host -foregroundcolor red "Error: invalid SHA. USAGE: $self <SHA>"
    #    popd
    #    break
    #}

    #Write-Output "Checking out $libgit2sha..."
    #Run-Command -Quiet -Fatal { & $git checkout $libgit2sha }

    #Pop-Location

    if (![string]::IsNullOrEmpty($libgit2Name)) {
        $libgit2binaryFilename = $libgit2Name
    } else {
        $libgit2binaryFilename = "git2-ssh-" + $libgit2sha.Substring(0,7)
    }

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libgit2_hash.txt") $libgit2sha
    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libgit2_filename.txt") $libgit2binaryFilename
	
    if (![string]::IsNullOrEmpty($libssh2Name)) {
        $libssh2binaryFilename = $libssh2Name
    } else {
        $libssh2binaryFilename = "libssh2-" + $libssh2sha.Substring(0,7)
    }

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libssh2_hash.txt") $libssh2sha
    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libssh2_filename.txt") $libssh2binaryFilename	
	
    if (![string]::IsNullOrEmpty($zlibName)) {
        $zlibbinaryFilename = $zlibName
    } else {
        $zlibbinaryFilename = "zlib-" + $zlibsha.Substring(0,7)
    }

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\zlib_hash.txt") $zlibsha
    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\zlib_filename.txt") $zlibbinaryFilename	
	
	$buildProperties = @"
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <ItemGroup>
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\libgit2_hash.txt" />
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\libgit2_filename.txt" />
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\libssh2_hash.txt" />
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\libssh2_filename.txt" />
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\zlib_hash.txt" />
        <EmbeddedResource Include="`$(MSBuildThisFileDirectory)\..\libgit2\zlib_filename.txt" />
    </ItemGroup>
    <ItemGroup>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libgit2binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libgit2binaryFilename.dll">
            <Link>lib\win32\x64\$libgit2binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libgit2binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libgit2binaryFilename.pdb">
            <Link>lib\win32\x64\$libgit2binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libgit2binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libgit2binaryFilename.dll">
            <Link>lib\win32\x86\$libgit2binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libgit2binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libgit2binaryFilename.pdb">
            <Link>lib\win32\x86\$libgit2binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libssh2binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libssh2binaryFilename.dll">
            <Link>lib\win32\x64\$libssh2binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libssh2binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$libssh2binaryFilename.pdb">
            <Link>lib\win32\x64\$libssh2binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libssh2binaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libssh2binaryFilename.dll">
            <Link>lib\win32\x86\$libssh2binaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libssh2binaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$libssh2binaryFilename.pdb">
            <Link>lib\win32\x86\$libssh2binaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$zlibbinaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$zlibbinaryFilename.dll">
            <Link>lib\win32\x64\$zlibbinaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$zlibbinaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x64\native\$zlibbinaryFilename.pdb">
            <Link>lib\win32\x64\$zlibbinaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$zlibbinaryFilename.dll')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$zlibbinaryFilename.dll">
            <Link>lib\win32\x86\$zlibbinaryFilename.dll</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$zlibbinaryFilename.pdb')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\win7-x86\native\$zlibbinaryFilename.pdb">
            <Link>lib\win32\x86\$zlibbinaryFilename.pdb</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>		
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\osx\native\lib$libgit2binaryFilename.dylib')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\osx\native\lib$libgit2binaryFilename.dylib">
            <Link>lib\osx\lib$libgit2binaryFilename.dylib</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Condition="Exists('`$(MSBuildThisFileDirectory)\..\runtimes\linux-x64\native\lib$libgit2binaryFilename.so')" Include="`$(MSBuildThisFileDirectory)\..\runtimes\linux-x64\native\lib$libgit2binaryFilename.so">
            <Link>lib\linux\x86_64\lib$libgit2binaryFilename.so</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
        <None Include="`$(MSBuildThisFileDirectory)\..\libgit2\LibGit2Sharp.dll.config">
            <Link>LibGit2Sharp.dll.config</Link>
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
        </None>
    </ItemGroup>
</Project>
"@

    sc -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\build\LibGit2Sharp.NativeBinaries.props") $buildProperties

    $dllConfig = @"
<configuration>
    <dllmap os="linux" cpu="x86-64" wordsize="64" dll="$libgit2binaryFilename" target="lib/linux/x86_64/lib$libgit2binaryFilename.so" />
    <dllmap os="osx" cpu="x86,x86-64" dll="$libgit2binaryFilename" target="lib/osx/lib$libgit2binaryFilename.dylib" />
</configuration>
"@

    sc -Encoding UTF8 (Join-Path $projectDirectory "nuget.package\libgit2\LibGit2Sharp.dll.config") $dllConfig

    Write-Output "Done!"
}
exit
