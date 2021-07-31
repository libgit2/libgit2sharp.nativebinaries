<#
  .SYNOPSIS
  Publish the NativeBinaries package + symbols

  .DESCRIPTION
  Invokes the `nuget push` command using the specified symbol and package sources. The script
  searches for `*.nupkg` files in the current working directory, but ignores files ending in
  `*.symbols.nupkg` (since nuget handles those for us).

  .PARAMETER PackagePushSource
  Source to push the package (`*.nupkg`) to. Can be a local file path if testing locally.

  .PARAMETER SymbolPushSource
  Source to push the package (`*.symbols.nupkg`) to. Can be a local file path if testing locally.
  Must be a path/URL different from the PackagePushSource.

  .INPUTS
  None. You cannot pipe objects into this script.

  .OUTPUTS
  None. This script does not generate any output.

  .EXAMPLE
  PS> Publish-Package.ps1

  Publishes the package (and symbol package) to C:\packages and C:\symbols, respectively. Useful for
  testing packages locally before publishing to nuget.org.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $PackagePushSource,

    [Parameter(Mandatory = $true)]
    [string] $SymbolPushSource
)

# Push options for nuget. The presence of `-SymbolSource` makes nuget upload the .symbols.nupkg
# files.
$PushPackageOptions = (
    "-Source", $PackagePushSource,
    "-SymbolSource", $SymbolPushSource
)

# Push the packages + symbols.
# Exclude symbol packages from the search because nuget handles those internally
Get-ChildItem ".\LibGit2Sharp.NativeBinaries.*.nupkg" -Exclude "*.symbols.nupkg" |
    ForEach-Object { .\nuget push $_.Name @PushPackageOptions }
