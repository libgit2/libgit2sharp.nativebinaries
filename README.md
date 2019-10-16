# LibGit2Sharp.NativeBinaries

**[Libgit2Sharp][lg2s]** is a managed wrapper around **[libgit2][lg2]**, and as
such requires compilation of libgit2 for your platform.  

LibGit2Sharp makes this easy by distributing, and leveraging as a dependency,
the **[LibGit2Sharp.NativeBinaries][lg2s-nb]** NuGet package.

This package contains the compiled versions of the libgit2 native library for
the following platforms:

 - Windows (x86/amd64)
 - Mac OS X (x86/amd64)
 - Linux (amd64)

**Note:** Due to the large number of distributions, the Linux support is
currently *experimental*. Would you encounter any issue with it, please open an
**[issue][tracker]**.

 [lg2s-nb]: https://www.nuget.org/packages/LibGit2Sharp.NativeBinaries
 [lg2]: https://libgit2.github.com/
 [lg2s]: http://libgit2sharp.com/
 [tracker]: https://github.com/libgit2/libgit2sharp.nativebinaries/issues

## How to update the native binaries for LibGit2Sharp

If you want to create a native binaries package for the
[LibGit2Sharp](https://github.com/libgit2/libgit2sharp) project, then there
is a simple process do so:

1. Clone the `LibGit2Sharp.NativeBinaries` repository.  Do so recursively
   to ensure that the `libgit2` submodule is initialized automatically:

   `git clone --recursive https://github.com/libgit2/libgit2sharp.nativebinaries`

   (If you have already cloned this repository (which seems quite
   likely since you are reading this file!) then you can simply run
   `git submodule init` followed by `git submodule update`.)

2. Update the included libgit2 sources and configuration files to the
   version of libgit2 you want to build.  For example, to build
   commit `1a2b3c4`:

   `UpdateLibgit2ToSha.ps1 1a2b3c4`

   Or you can specify references.  To build the remote's `master` branch:

   `UpdateLibgit2ToSha.ps1 master`

   This will update the libgit2 submodule, and update the references within
   the project to the correct libgit2 revision.

3. Check these changes in, then open a pull request to the
   [`LibGit2Sharp.NativeBinaries`](https://github.com/libgit2/LibGit2Sharp.NativeBinaries)
   project and get the changes reviewed and merged into `master`.


4. Once merged, the Travis and AppVeyor builds will run.  Once those
   are done, you can create the nativebinaries nuget package from the
   build artifacts that were created by the CI systems.

   `download.build.artifacts.and.package.ps1`

   This will emit a nuget package, eg `LibGit2Sharp.NativeBinaries.2.0.291.nupkg`.

5. Upload the package created in step 4 to [nuget.org](https://nuget.org/).

6. Now you can update [LibGit2Sharp](https://github.com/libgit2/libgit2sharp)
   to reference this package.
   
   **Note**: the package reference should pin to the NativeBinaries package version
   _exactly_, it should not allow for a nativebinaries range.  This is for strict
   ABI compatibiity.  The `PackageReference` in the LibGit2Sharp project should be
   `[2.0.291]` (with square brackets).

## How to build custom native binaries for your own project

If you use this native binaries package for your own project (a fork of
LibGit2Sharp, or something else entirely) then you can also use the tools
in this project to do that:

1. Clone the `LibGit2Sharp.NativeBinaries` repository.  Do so recursively
   to ensure that the `libgit2` submodule is initialized automatically:

   `git clone --recursive https://github.com/libgit2/libgit2sharp.nativebinaries`

   (If you have already cloned this repository (which seems quite
   likely since you are reading this file!) then you can simply run
   `git submodule init` followed by `git submodule update`.)

2. Update the included libgit2 sources and configuration files to the
   version of libgit2 you want to build.  For example, to build
   commit `1a2b3c4`:

   `UpdateLibgit2ToSha.ps1 1a2b3c4`

   Or you can specify references.  To build the remote's `master` branch:

   `UpdateLibgit2ToSha.ps1 master`

3. Build the libgit2 binaries.  For Windows, this requires a Visual Studio
   installation, and will compile both x86 and amd64 variants.  (See
   "Notes on Visual Studio", below).  Run the build PowerShell script,
   specifying the version number of Visual Studio as the first argument.
   For example, to build with Visual Studio 2013 (aka "Visual Studio 12.0"):

   `build.libgit2.ps1 12`

   For Linux, this will build only the architecture that you're running
   (x86 or amd64).  For Mac OS X, this will build a fat library that
   includes both x86 and amd64.  Run the shell script:

   `build.libgit2.sh`

4. Create the NuGet package from the built binaries.  You will need to
   specify the version number of the resultant NuGet package that you
   want to generate.  Note that you may wish to provide a suffix to
   disambiguate your custom package from the official, published NuGet
   packages.  For example, if you are building a product called
   `fooproduct` then that may be a helpful suffix.

    To build a NuGet package at version `1.2.3-foo`:

   `buildpackage.ps1 1.2.3-foo`

   And the result will be a NuGet package in the current directory:

   `LibGit2Sharp.NativeBinaries.1.2.3-foo.nupkg`

   Note that the `-foo` suffix technically makes this a "prerelease"
   package, according to NuGet, which may be further help in avoiding
   any mixups with the official packages, but may also require you to
   opt-in to prerelease packages in your NuGet package manager.

## Specifying custom DLL names

If you want to redistribute a LibGit2Sharp that uses a custom libgit2,
you may want to change the name of the libgit2 shared library file to
disambiguate it from other installations.  This may be useful if you
are running as a plugin inside a larger process and wish to avoid
conflicting with other plugins who may wish to use LibGit2Sharp and
want to ensure that *your* version of libgit2 is loaded into memory
and available to you.

For example, if your plugin names if `fooplugin`, you may wish to
distribute a DLL named `git2-fooplugin.dll`.  You can specify the
custom DLL name as the second argument to the update and build scripts:

    UpdateLibgit2ToSha.ps1 1a2b3c4 git2-fooplugin
    build.libgit2.sh 14 git2-fooplugin

Then build the NuGet package as described above, making sure to provide
a helpful suffix to ensure that your NuGet package will not be confused
with the official packages.

### Notes on Visual Studio

Visual Studio is required to build the native binaries, however you
do not need to install a *paid* version of Visual Studio.  libgit2
can be compiled using [Visual Studio Community](https://www.visualstudio.com/en-us/products/visual-studio-community-vs),
which is free for building open source applications.

You need to specify the actual version number (not the marketing name)
of Visual Studio.  (For example, "Visual Studio 2013" is the name of the
product, but its actual version number is "12.0".)  A handy guide:

| Marketing Name     | Version Number
|--------------------|---------------
| Visual Studio 2010 | 10
| Visual Studio 2012 | 11
| Visual Studio 2013 | 12
| Visual Studio 2015 | 14
| Visual Studio 2017 | 15
