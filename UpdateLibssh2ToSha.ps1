<#
.SYNOPSIS
    Updates the libssh2 submodule to the specified commit and updates libssh2_hash.txt and NativeBinaries.props with the new hash value.
.PARAMETER sha
    Desired libssh2 version. This is run through `git rev-parse`, so branch names are okay too.
#>

Param(
    [string]$sha = 'HEAD',
    [string]$libssh2Name = ''
)

Set-StrictMode -Version Latest

$self = Split-Path -Leaf $MyInvocation.MyCommand.Path
$projectDirectory = Split-Path $MyInvocation.MyCommand.Path
$libssh2Directory = Join-Path $projectDirectory "libssh2"

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

Push-Location $libssh2Directory

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

    if (![string]::IsNullOrEmpty($libssh2Name)) {
        $binaryFilename = $libssh2Name
    } else {
        $binaryFilename = "libssh2-" + $sha.Substring(0,7)
    }

    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libssh2_hash.txt") $sha
    sc -Encoding ASCII (Join-Path $projectDirectory "nuget.package\libgit2\libssh2_filename.txt") $binaryFilename

    Write-Output "Done!"
}
exit
