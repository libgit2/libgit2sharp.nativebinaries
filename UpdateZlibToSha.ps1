<#
.SYNOPSIS
    Updates the zlib submodule to the specified commit and updates libgit2_hash.txt and NativeBinaries.props with the new hash value.
.PARAMETER sha
    Desired zlib version. This is run through `git rev-parse`, so branch names are okay too.
#>

Param(
    [string]$sha = 'HEAD',
    [string]$zlibName = ''
)

Set-StrictMode -Version Latest

$self = Split-Path -Leaf $MyInvocation.MyCommand.Path
$projectDirectory = Split-Path $MyInvocation.MyCommand.Path
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

Push-Location $zlibDirectory

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

    if (![string]::IsNullOrEmpty($zlibName)) {
        $binaryFilename = $zlibName
    } else {
        $binaryFilename = "zlib-" + $sha.Substring(0,7)
    }

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\zlib_hash.txt") $sha
    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\zlib_filename.txt") $binaryFilename

    Write-Output "Done!"
}
exit
