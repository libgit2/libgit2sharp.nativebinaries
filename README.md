# LibGit2Sharp.NativeBinaries

This repository host the packaging process to generate the **[LibGit2Sharp.NativeBinaries][0]** NuGet package.

This package contains the compiled versions of the **[libgit2][1]** native library for Windows (x86/amd64), Mac OS X (x86/amd64) and Linux (amd64) and is used as a dependency by the **[LibGit2Sharp][2]** library.

**Note:** Due to the large number of distributions, the Linux support is currently *experimental*. Would you encounter any issue with it, please open an **[issue][3]**.

 [0]: https://www.nuget.org/packages/LibGit2Sharp.NativeBinaries
 [1]: https://libgit2.github.com/
 [2]: http://libgit2sharp.com/
 [3]: https://github.com/libgit2/libgit2sharp.nativebinaries/issues
## First time setup

### Fork the repository

- Navigate to https://github.com/libgit2/libgit2sharp.nativebinaries
- Click the **Fork** button
- Clone your fork

  ```bash
  $ git clone --recursive https://github.com/{your_github_handle}/libgit2sharp.nativebinaries.
  git
  Cloning into 'libgit2sharp.nativebinaries'...
  remote: Counting objects: 23, done.
  remote: Compressing objects: 100% (6/6), done.
  remote: Total 23 (delta 0), reused 0 (delta 0), pack-reused 17
  Unpacking objects: 100% (23/23), done.
  Checking connectivity... done.
  Submodule 'libgit2' (https://github.com/libgit2/libgit2.git) registered for path
   'libgit2'
  Cloning into 'libgit2'...
  remote: Counting objects: 61138, done.
  remote: Compressing objects: 100% (17692/17692), done.
  remote: Total 61138 (delta 42295), reused 61076 (delta 42233), pack-reused 0
  Receiving objects: 100% (61138/61138), 25.11 MiB | 5.09 MiB/s, done.
  Resolving deltas: 100% (42295/42295), done.
  Checking connectivity... done.
  Submodule path 'libgit2': checked out '9bbc8f350b80a5a6e94651ec667cf9e5d545b317'
  ```

- Register the main repository as an additional remote

  ```bash
  $ cd libgit2sharp.nativebinaries/

  $ git remote add upstream https://github.com/libgit2/libgit2sharp.nativebinaries.git

  $ git remote -v
  origin    https://github.com/{your_github_handle}/libgit2sharp.nativebinaries.git (fetch)
  origin    https://github.com/{your_github_handle}/libgit2sharp.nativebinaries.git (push)
  upstream  https://github.com/libgit2/libgit2sharp.nativebinaries.git (fetch)
  upstream  https://github.com/libgit2/libgit2sharp.nativebinaries.git (push)
  ```

## Update your fork with the latest upstream changes

```bash
$ git fetch --recurse-submodules upstream

$ git checkout master
Switched to branch 'master'

$ git merge --ff-only upstream/master
Updating 0b31090..e1e5fe6
Fast-forward
[...]

$ git push origin master
```

## Upgrading to the latest libgit2 version

- Create a local topic branch

  ```bash
  $ git checkout -b my_upgrade
  Switched to a new branch 'my_upgrade'
  ```

- Update the local repository with the latest upstream changes (from a PowerShell console)

  ```powershell
  PS > .\UpdateLibgit2ToSha.ps1 origin/HEAD
  Using git: C:\Program Files (x86)\Git\cmd\git.exe
  git version 1.9.5.msysgit.0
  Fetching...
  Verifying origin/HEAD...
  Checking out deafbeedcafeabad1dea906ed693a862a250664b...
  Done!
  ```

- Check the changes

  ```bash
  $ git status
  On branch my_upgrade
  Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
    (use "git checkout -- <file>..." to discard changes in working directory)

          modified:   libgit2 (new commits)
          modified:   nuget.package/build/LibGit2Sharp.NativeBinaries.props
          modified:   nuget.package/libgit2/libgit2_hash.txt

  no changes added to commit (use "git add" and/or "git commit -a")
  ```

- Identify the old and new ligit2 commit shas

  ```bash
  $ git diff nuget.package/libgit2/libgit2_hash.txt
  diff --git a/nuget.package/libgit2/libgit2_hash.txt b/nuget.package/libgit2/libgit2_hash.txt
  index 1f04184..fa418fe 100644
  --- a/nuget.package/libgit2/libgit2_hash.txt
  +++ b/nuget.package/libgit2/libgit2_hash.txt
  @@ -1 +1 @@
  -9bbc8f350b80a5a6e94651ec667cf9e5d545b317
  +9042693e283f65d9afb4906ed693a862a250664b
  ```
- Commit the changes

  ```bash
  $ git commit -a
  ```

- Use the following pattern to compose the commit message

  ```
  Update libgit2 to {new_abbrev_sha}

  https://github.com/libgit2/libgit2/compare/{old_abbrev_sha}...{new_abbrev_sha}

  # Example:
  #
  # Update libgit2 to 9042693
  #
  # https://github.com/libgit2/libgit2/compare/9bbc8f3...9042693
  ```
- Push your changes to your fork

  ```bash
  $ git push origin my_upgrade
  Counting objects: 13, done.
  Delta compression using up to 8 threads.
  Compressing objects: 100% (6/6), done.
  Writing objects: 100% (7/7), 760 bytes | 0 bytes/s, done.
  Total 7 (delta 3), reused 0 (delta 0)
  To https://github.com/{your-github_handle}/libgit2sharp.nativebinaries.git
   * [new branch]      my_upgrade -> my_upgrade
  ```

- Navigate to your fork and open a Pull Request

## Testing the upgraded libgit2 bits from LibGit2Sharp

- From the opened pull request, navigate to the related `AppVeyor` build
 - Switch the `Artifacts` tab
 - Download the generated NuGet package (eg. `LibGit2Sharp.NativeBinaries.1.0.52-pre20150617064648.nupkg`)

- Create a local topic branch
- Configure VisualStudio to accept a local NuGet package source
 - Tools > Options > NuGet Package Manager > Package Sources
 - Create a new source pointing at the folder containing the generated package

- Make LibGit2Sharp leverage the new libgit2 binaries
 - Open the `LibGit2Sharp\packages.config` file
 - Change the value of the `allowedVersions` attribute to target the new package (eg. [1.0.51] -> [1.0.52-pre20150617064648])
 - Save your changes
 - Right-click the LibGit2Sharp project in the Solution Explorer, then select `Manage NuGet Packages`
 - Switch over to the `Updates` tabs, select your local source
 - Ensure the `Include Prerelease` option has been selected
 - The new package should be listed. Click `Update`

- Check the changes

  ```bash
  $ git status
  On branch libgit2_upgrade
  Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
    (use "git checkout -- <file>..." to discard changes in working directory)

          modified:   LibGit2Sharp/LibGit2Sharp.csproj
          modified:   LibGit2Sharp/packages.config

  no changes added to commit (use "git add" and/or "git commit -a")

  $ git diff
  diff --git a/LibGit2Sharp/LibGit2Sharp.csproj b/LibGit2Sharp/LibGit2Sharp.csproj
  index 7215309..586c343 100644
  --- a/LibGit2Sharp/LibGit2Sharp.csproj
  +++ b/LibGit2Sharp/LibGit2Sharp.csproj
  @@ -1,6 +1,6 @@
   ﻿<?xml version="1.0" encoding="utf-8"?>
   <Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  -  <Import Project="..\packages\LibGit2Sharp.NativeBinaries.1.0.51\build\LibGit2Sharp.NativeBinaries.props" Condition="Exists('..\packages\LibGit2Sharp.NativeBinaries.1.0.51\build\LibGit2Sharp.NativeBinaries.props')" />
  +  <Import Project="..\packages\LibGit2Sharp.NativeBinaries.1.0.52-pre20150617064648\build\LibGit2Sharp.NativeBinaries.props" Condition="Exists('..\packages\LibGit2Sharp.NativeBinaries.1.0.52-pre20150617064648\build\LibGit2Sharp.NativeBinaries.props')" />
     <PropertyGroup>
       <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
       <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
  @@ -392,7 +392,7 @@
       <PropertyGroup>
         <ErrorText>This project references NuGet package(s) that are missing on this computer. Enable NuGet Package Restore to download them.  For more information, see http://go.microsoft.com/fwlink/?LinkID=322105. The missing file is {0}.</ErrorText>
       </PropertyGroup>
  -    <Error Condition="!Exists('..\packages\LibGit2Sharp.NativeBinaries.1.0.51\build\LibGit2Sharp.NativeBinaries.props')" Text="$([System.String]::Format('$(ErrorText)', '..\packages\LibGit2Sharp.NativeBinaries.1.0.51\build\LibGit2Sharp.NativeBinaries.props'))" />
  +    <Error Condition="!Exists('..\packages\LibGit2Sharp.NativeBinaries.1.0.52-pre20150617064648\build\LibGit2Sharp.NativeBinaries.props')" Text="$([System.String]::Format('$(ErrorText)', '..\packages\LibGit2Sharp.NativeBinaries.1.0.52-pre20150617064648\build\LibGit2Sharp.NativeBinaries.props'))" />
     </Target>
     <!-- To modify your build process, add your task inside one of the targets below and uncomment it.
          Other similar extension points exist, see Microsoft.Common.targets.
  diff --git a/LibGit2Sharp/packages.config b/LibGit2Sharp/packages.config
  index 6565d17..5331bee 100644
  --- a/LibGit2Sharp/packages.config
  +++ b/LibGit2Sharp/packages.config
  @@ -1,4 +1,4 @@
  <?xml version="1.0" encoding="utf-8"?>
   <packages>
  -  <package id="LibGit2Sharp.NativeBinaries" version="1.0.51" targetFramework="net40" allowedVersions="[1.0.51]" />
  +  <package id="LibGit2Sharp.NativeBinaries" version="1.0.52-pre20150617064648" targetFramework="net40" allowedVersions="[1.0.52-pre20150617064648]" />
   </packages>
  \ No newline at end of file
  ```
- Update LibGit2Sharp to cope with the potential changes in the libgit2 API
- Locally run all the LibGit2Sharp tests
