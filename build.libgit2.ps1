<#
.SYNOPSIS
    Builds a version of libgit2 and copies it to the nuget packaging directory.
.PARAMETER test
    If set, run the libgit2 tests on the desired version.
.PARAMETER debug
    If set, build the "Debug" configuration of libgit2, rather than "Release" (default).
.PARAMETER x86
    If set, the 32-bit version will be built.
.PARAMETER x64
    If set, the 64-bit version will be built.
#>

Param(
    [switch]$test,
    [switch]$debug,
    [switch]$x86,
    [switch]$x64
)

Set-StrictMode -Version Latest

$projectDirectory = Split-Path $MyInvocation.MyCommand.Path
$libgit2Directory = Join-Path $projectDirectory "libgit2"
$x86Directory = Join-Path $projectDirectory "nuget.package\runtimes\win-x86\native"
$x64Directory = Join-Path $projectDirectory "nuget.package\runtimes\win-x64\native"
$hashFile = Join-Path $projectDirectory "nuget.package\libgit2\libgit2_hash.txt"
$sha = Get-Content $hashFile 
$binaryFilename = "git2-" + $sha.Substring(0,7)

$build_clar = 'OFF'
if ($test.IsPresent) { $build_clar = 'ON' }

$configuration = "Release"
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

    # Patch CMakeLists.txt to fix LIBGIT2_FILENAME not being used when compiling the .rc file
    # To remove when https://github.com/libgit2/libgit2/pull/5994 is included
    $libgit2CMakeLists = Join-Path $libgit2Directory "src\CMakeLists.txt"
    (Get-Content $libgit2CMakeLists).Replace('target_compile_definitions(git2internal PRIVATE LIBGIT2_FILENAME', 'target_compile_definitions(git2 PRIVATE LIBGIT2_FILENAME') | Set-Content $libgit2CMakeLists

    $cmake = Find-CMake
    $ctest = Join-Path (Split-Path -Parent $cmake) "ctest.exe"

    Run-Command -Quiet { & remove-item build -recurse -force -ErrorAction Ignore }
    Run-Command -Quiet { & mkdir build }
    cd build

    if ($x86.IsPresent) {
        Write-Output "Building 32-bit..."
        Run-Command -Fatal { & $cmake -G "Visual Studio 16 2019" -A Win32 -D ENABLE_TRACE=ON -D USE_SSH=OFF -D "BUILD_CLAR=$build_clar" -D "LIBGIT2_FILENAME=$binaryFilename"  .. }
        Run-Command -Fatal { & $cmake --build . --config $configuration }
        if ($test.IsPresent) { Run-Command -Quiet -Fatal { & $ctest -V . } }
        cd $configuration
        Assert-Consistent-Naming "$binaryFilename.dll" "*.dll"
        Run-Command -Quiet { & rm *.exp }
        Run-Command -Quiet { & rm $x86Directory\* -ErrorAction Ignore }
        Run-Command -Quiet { & mkdir -fo $x86Directory }
        Run-Command -Quiet -Fatal { & copy -fo * $x86Directory -Exclude *.lib }
        cd ..
    }

    if ($x64.IsPresent) {
        Write-Output "Building 64-bit..."
        Run-Command -Quiet { & mkdir build64 }
        cd build64
        Run-Command -Fatal { & $cmake -G "Visual Studio 16 2019" -A x64 -D THREADSAFE=ON -D USE_SSH=OFF -D ENABLE_TRACE=ON -D "BUILD_CLAR=$build_clar" -D "LIBGIT2_FILENAME=$binaryFilename" ../.. }
        Run-Command -Fatal { & $cmake --build . --config $configuration }
        if ($test.IsPresent) { Run-Command -Quiet -Fatal { & $ctest -V . } }
        cd $configuration
        Assert-Consistent-Naming "$binaryFilename.dll" "*.dll"
        Run-Command -Quiet { & rm *.exp }
        Run-Command -Quiet { & rm $x64Directory\* -ErrorAction Ignore }
        Run-Command -Quiet { & mkdir -fo $x64Directory }
        Run-Command -Quiet -Fatal { & copy -fo * $x64Directory -Exclude *.lib }
    }

    Write-Output "Done!"
}
finally {
    Pop-Location
}
