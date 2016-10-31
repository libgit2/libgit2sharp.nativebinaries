<#
.SYNOPSIS
    Builds a version of libgit2 and copies it to the nuget packaging directory.
.PARAMETER vs
    Version of Visual Studio project files to generate. Cmake supports "10" (default), "11" and "12".
.PARAMETER test
    If set, run the libgit2 tests on the desired version.
.PARAMETER debug
    If set, build the "Debug" configuration of libgit2, rather than "RelWithDebInfo" (default).
.PARAMETER libssh2
    If set, build external zlib, libssh2.
.PARAMETER embed
    If set, build embedded libssh2.
.PARAMETER cdecl
	If set, build all libraries with STDCALL convention, otherwise CDECL (default)
.PARAMETER dynamic
	If set, build all libraries with static linked CRT, otherwise dynamic (default)
#>

Param(
    [string]$vs = '10',
    [string]$libgit2Name = '',
    [switch]$test,
    [switch]$debug
	[switch]$libssh2,
	[switch]$embed,
	[switch]$cdecl,
	[switch]$dynamic,
)

Set-StrictMode -Version Latest

$projectDirectory = Split-Path $MyInvocation.MyCommand.Path
$libgit2Directory = Join-Path $projectDirectory "libgit2"
$libssh2Directory = Join-Path $projectDirectory "libssh2"
$zlibDirectory = Join-Path $projectDirectory "zlib"
$x86Directory = Join-Path $projectDirectory "nuget.package\runtimes\win7-x86\native"
$x64Directory = Join-Path $projectDirectory "nuget.package\runtimes\win7-x64\native"
$hashFile = Join-Path $projectDirectory "nuget.package\libgit2\libgit2_hash.txt"
$sha = Get-Content $hashFile 

if (![string]::IsNullOrEmpty($libgit2Name)) {
    $binaryFilename = $libgit2Name
} else {
    $binaryFilename = "libgit2-ssh-" + $sha.Substring(0,7)
}

$build_clar = 'OFF'
if ($test.IsPresent) { $build_clar = 'ON' }

$configuration = "RelWithDebInfo"
if ($debug.IsPresent) { $configuration = "Debug" }

$libssh2_embed = 'OFF'
if ($libssh2.IsPresent -And $embed) { $libssh2_embed = $libssh2Directory -replace "\\", "/" }

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

function Build-Zlib([switch]$x64) {
	$architecture = "32-bit"
	$arch = "x86"
	$gen = "Visual Studio $vs"
	$outputDirectory = $x86Directory
	
	if ($x64) {
		$architecture = "64-bit"
		$arch = "x64"
		$gen = "Visual Studio $vs Win64"
		$outputDirectory = $x64Directory
	}
	
	Push-Location $zlibDirectory
	
	Write-Output "`tBuilding $architecture zlib..."
	
	Run-Command -Quiet { & remove-item build/$arch -recurse -force }
	Run-Command -Quiet { & remove-item install/$arch -recurse -force }
	Run-Command -Quiet { & mkdir build/$arch }
	cd build/$arch
	# Make STDCALL and static linked CRT
	Run-Command -Quiet -Fatal { & $cmake -G $gen -DCMAKE_C_FLAGS="/DWIN32 /D_WINDOWS /W3 /Gz" -DCMAKE_C_FLAGS_DEBUG="/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1" -DCMAKE_C_FLAGS_MINSIZEREL="/MT /O1 /Ob1 /D NDEBUG" -DCMAKE_FLAGS_RELEASE="/MT /O2 /Ob2 /D NDEBUG" -DCMAKE_C_FLAGS_RELWITHDEBINFO="/MT /Zi /O2 /Ob1 /D NDEBUG" -D "CMAKE_INSTALL_PREFIX=$zlibDirectory/install/$arch" ../.. }
	Run-Command -Quiet -Fatal { & $cmake --build . --config $configuration --target install }
	
	# Prepare to publish
	cd $zlibDirectory/install/$arch/bin
    Run-Command -Quiet -Fatal { & copy -fo * $outputDirectory -Exclude *.lib }
	
	# Clear submodule
	Run-Command -Quiet { & remove-item build/$arch -recurse -force }
	Run-Command -Quiet { & remove-item install/$arch -recurse -force }
			
	Pop-Location
}

function Build-Libssh2([switch]$x64) {
	$architecture = "32-bit"
	$arch = "x86"
	$gen = "Visual Studio $vs"
	$outputDirectory = $x86Directory
	
	if ($x64) {
		$architecture = "64-bit"
		$arch = "x64"
		$gen = "Visual Studio $vs Win64"
		$outputDirectory = $x64Directory
	}
	
	$libssh2Dir = $libssh2Directory -replace "\\", "/"
	$zlibDir = $zlibDirectory -replace "\\", "/"
	
	Push-Location $libssh2Directory
	
	Write-Output "`tBuilding $architecture libssh2..."
	
	Run-Command -Quiet { & remove-item build/$arch -recurse -force }
	Run-Command -Quiet { & remove-item install/$arch -recurse -force }
	Run-Command -Quiet { & mkdir build/$arch }
	cd build/$arch
	# Make STDCALL and static linked CRT
	Run-Command -Quiet -Fatal { & $cmake -G $gen -DCMAKE_C_FLAGS="/DWIN32 /D_WINDOWS /W3 /Gz" -DCMAKE_C_FLAGS_DEBUG="/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1" -DCMAKE_C_FLAGS_MINSIZEREL="/MT /O1 /Ob1 /D NDEBUG" -DCMAKE_FLAGS_RELEASE="/MT /O2 /Ob2 /D NDEBUG" -DCMAKE_C_FLAGS_RELWITHDEBINFO="/MT /Zi /O2 /Ob1 /D NDEBUG" -D "CMAKE_INSTALL_PREFIX=$libssh2Dir/install/$arch" -D BUILD_TESTING=ON -D BUILD_SHARED_LIBS=ON -D ENABLE_ZLIB_COMPRESSION=ON -D "ZLIB_LIBRARY=$zlibDir/install/$arch/lib/zlib.lib" -D "ZLIB_INCLUDE_DIR=$zlibDir/install/$arch/include" ../.. }
	Run-Command -Quiet -Fatal { & $cmake --build . --config $configuration --target install }
	
	# Prepare to publish
	cd $libssh2Dir/install/$arch/bin
    Run-Command -Quiet -Fatal { & copy -fo * $outputDirectory -Exclude *.lib }
	
	# Clear submodule
	Run-Command -Quiet { & remove-item build/$arch -recurse -force }
	Run-Command -Quiet { & remove-item install/$arch -recurse -force }
			
	Pop-Location
}

function Build-Libgit2([switch]$x64, [switch]$extZlib) {
	$architecture = "32-bit"
	$arch = "x86"
	$gen = "Visual Studio $vs"
	$build = "build"
	$outputDirectory = $x86Directory
	$root = ".."
	$zlibDir = "../../zlib"
	
	if ($x64) {
		$architecture = "64-bit"
		$arch = "x64"
		$gen = "Visual Studio $vs Win64"
		$build = "build/build64"
		$outputDirectory = $x64Directory
		$root = "../.."
		$zlibDir = "../../../zlib"
	}
	
	$libgit2Dir = $libgit2Directory -replace "\\", "/"
	$libssh2Dir = $libssh2Directory -replace "\\", "/"	
	
	Push-Location $libgit2Directory
	
	Write-Output "`tBuilding $architecture libgit2..."
	
	Run-Command -Quiet { & remove-item $build -recurse -force }
	Run-Command -Quiet { & mkdir $build }
	cd $build

	if ($extZlib) {
		Run-Command -Quiet -Fatal { & $cmake -G $gen -DSTDCALL=ON -D ENABLE_TRACE=ON -D "ZLIB_LIBRARY_RELEASE=$zlibDir/install/$arch/lib/zlib.lib" -D "ZLIB_INCLUDE_DIR=$zlibDir/install/$arch/include" -D USE_SSH=ON -D LIBSSH2_FOUND=ON -D "LIBSSH2_INCLUDE_DIRS=$libssh2Dir/install/$arch/include" -D "LIBSSH2_LIBRARIES=$libssh2Dir/install/$arch/lib/libssh2.lib" -D "BUILD_CLAR=$build_clar" -D "LIBGIT2_FILENAME=$binaryFilename" -D "EMBED_SSH_PATH=$libssh2_embed" $root }
	} else {
		Run-Command -Quiet -Fatal { & $cmake -G $gen -DSTDCALL=ON -D ENABLE_TRACE=ON -D "BUILD_CLAR=$build_clar" -D "LIBGIT2_FILENAME=$binaryFilename" -D "EMBED_SSH_PATH=$libssh2_embed" $root }
	}

	Run-Command -Quiet -Fatal { & $cmake --build . --config $configuration }
	if ($test.IsPresent) { Run-Command -Quiet -Fatal { & $ctest -V . } }
    cd $configuration
    Assert-Consistent-Naming "$binaryFilename.dll" "*.dll"
    Run-Command -Quiet { & rm *.exp }
    Run-Command -Quiet -Fatal { & copy -fo * $outputDirectory -Exclude *.lib }
			
	Pop-Location
}

try {
    Push-Location $libgit2Directory

    $cmake = Find-CMake
    $ctest = Join-Path (Split-Path -Parent $cmake) "ctest.exe"

    # Write-Output "Building 32-bit..."

	Run-Command -Quiet { & rm $x86Directory\* }
    Run-Command -Quiet { & mkdir -fo $x86Directory }

	if ($libssh2.IsPresent -And !$embed) {
		Build-Zlib
		Build-Libssh2
		Build-Libgit2 -extZlib
	} else {
		Build-Libgit2
	}
		
	# Write-Output "Building 64-bit..."
	
	Run-Command -Quiet { & rm $x64Directory\* }
    Run-Command -Quiet { & mkdir -fo $x64Directory }
	
	if ($libssh2.IsPresent -And !$embed) {
		Build-Zlib -x64
		Build-Libssh2 -x64
		Build-Libgit2 -x64 -extZlib
	} else {
		Build-Libgit2 -x64
	}
		
    Write-Output "Done!"
}
finally {
    Pop-Location
}
