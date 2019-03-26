<#
.SYNOPSIS
    Builds a version of libgit2 and copies it to the nuget packaging directory.
.PARAMETER vs
    Version of Visual Studio project files to generate. Cmake supports "10" (default), "11" and "12".
.PARAMETER test
    If set, run the libgit2 tests on the desired version.
.PARAMETER debug
    If set, build the "Debug" configuration of libgit2, rather than "RelWithDebInfo" (default).
#>

Param(
    [string]$vs = '15',
    [string]$libgit2Name = '',
    [switch]$test,
    [switch]$debug
)

Set-StrictMode -Version Latest

$projectDirectory = Split-Path $MyInvocation.MyCommand.Path
$libgit2Directory = Join-Path $projectDirectory "libgit2"
$libssh2Directory = ([System.Uri](Join-Path $projectDirectory "libssh2")).AbsolutePath 
$x86Directory = Join-Path $projectDirectory "nuget.package\runtimes\win-x86\native"
$x64Directory = Join-Path $projectDirectory "nuget.package\runtimes\win-x64\native"
$hashFile = Join-Path $projectDirectory "nuget.package\libgit2\libgit2_hash.txt"
$sha = Get-Content $hashFile 

if (![string]::IsNullOrEmpty($libgit2Name)) {
    $binaryFilename = $libgit2Name
} else {
    $binaryFilename = "git2-" + $sha.Substring(0,7)
}

$build_clar = 'OFF'
if ($test.IsPresent) { $build_clar = 'ON' }

$configuration = "RelWithDebInfo"
if ($debug.IsPresent) { $configuration = "Debug" }

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

function Find-CMake {
    # Look for cmake.exe in $Env:PATH.
    $cmake = @(Get-Command cmake.exe)[0] 2>$null
    if ($cmake) {
        $cmake = $cmake.Definition
    } else {
        # Look for the highest-versioned cmake.exe in its default location.
        $cmake = @(Resolve-Path (Join-Path ${Env:ProgramFiles(x86)} "CMake *\bin\cmake.exe"))
        if ($cmake) {
            $cmake = $cmake[-1].Path
        }
    }
    if (!$cmake) {
        throw "Error: Can't find cmake.exe"
    }
    $cmake
}

function Ensure-Property($expected, $propertyValue, $propertyName, $path) {
    if ($propertyValue -eq $expected) {
        return
    }

    throw "Error: Invalid '$propertyName' property in generated '$path' (Expected: $expected - Actual: $propertyValue)"
}

function Assert-Consistent-Naming($expected, $path) {
    $dll = get-item $path

    Ensure-Property $expected $dll.Name "Name" $dll.Fullname
    Ensure-Property $expected $dll.VersionInfo.InternalName "VersionInfo.InternalName" $dll.Fullname
    Ensure-Property $expected $dll.VersionInfo.OriginalFilename "VersionInfo.OriginalFilename" $dll.Fullname
}

try {
    Push-Location $libgit2Directory

    $cmake = Find-CMake
    $ctest = Join-Path (Split-Path -Parent $cmake) "ctest.exe"

    Write-Output "Building 32-bit..."
    Run-Command -Quiet { & remove-item build -recurse -force }
    Run-Command -Quiet { & mkdir build }
    cd build
    Run-Command -Quiet -Fatal { & $cmake -G "Visual Studio $vs" -D ENABLE_TRACE=ON -D "BUILD_CLAR=$build_clar" -D "LIBGIT2_FILENAME=$binaryFilename" -D "EMBED_SSH_PATH=$libssh2Directory" .. }
    Run-Command -Quiet -Fatal { & $cmake --build . --config $configuration }
    if ($test.IsPresent) { Run-Command -Quiet -Fatal { & $ctest -V . } }
    cd $configuration
    Assert-Consistent-Naming "$binaryFilename.dll" "*.dll"
    Run-Command -Quiet { & rm *.exp }
    Run-Command -Quiet { & rm $x86Directory\* }
    Run-Command -Quiet { & mkdir -fo $x86Directory }
    Run-Command -Quiet -Fatal { & copy -fo * $x86Directory -Exclude *.lib }

    Write-Output "Building 64-bit..."
    cd ..
    Run-Command -Quiet { & mkdir build64 }
    cd build64
    Run-Command -Quiet -Fatal { & $cmake -G "Visual Studio $vs Win64" -D THREADSAFE=ON -D ENABLE_TRACE=ON -D "BUILD_CLAR=$build_clar" -D "LIBGIT2_FILENAME=$binaryFilename" -D "EMBED_SSH_PATH=$libssh2Directory" ../.. }
    Run-Command -Quiet -Fatal { & $cmake --build . --config $configuration }
    if ($test.IsPresent) { Run-Command -Quiet -Fatal { & $ctest -V . } }
    cd $configuration
    Assert-Consistent-Naming "$binaryFilename.dll" "*.dll"
    Run-Command -Quiet { & rm *.exp }
    Run-Command -Quiet { & rm $x64Directory\* }
    Run-Command -Quiet { & mkdir -fo $x64Directory }
    Run-Command -Quiet -Fatal { & copy -fo * $x64Directory -Exclude *.lib }

    Write-Output "Done!"
}
finally {
    Pop-Location
}
