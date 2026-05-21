# libgit2 native binaries nuget package

[![CI](https://github.com/gigi81/libgit2sharp-nativebinaries/actions/workflows/ci.yml/badge.svg)](https://github.com/gigi81/libgit2sharp-nativebinaries/actions/workflows/ci.yml)

This is a modernized fork of the original `LibGit2Sharp.NativeBinaries` project. It provides the native `libgit2` binaries required by [LibGit2Sharp](https://github.com/libgit2/libgit2sharp).

## Key Enhancements

*   **Expanded Architecture Support:** Now supports 12 RIDs including Windows (x86, x64, ARM64), macOS (x64, ARM64), Linux Glibc (x64, ARM, ARM64, PPC64LE), and Linux Musl (x64, ARM, ARM64).
*   **Pure CMake Build:** Replaced legacy shell scripts and complex Docker setups with a standard CMake workflow, making the build process more transparent and easier to maintain.
*   **Modern CI/CD:** Fully automated GitHub Actions pipeline that builds, packages, and publishes to GitHub Packages and NuGet.org.
*   **Deterministic Versioning:** Package versions are automatically derived from the underlying `libgit2` source version with an appended build number for unique releases.

## Supported RIDs

| Operating System | Architecture | RID |
| :--- | :--- | :--- |
| **Windows** | x86, x64, ARM64 | `win-x86`, `win-x64`, `win-arm64` |
| **macOS** | x64, ARM64 (M-series) | `osx-x64`, `osx-arm64` |
| **Linux (Glibc)** | x64, ARM, ARM64, PPC64LE | `linux-x64`, `linux-arm`, `linux-arm64`, `linux-ppc64le` |
| **Linux (Musl)** | x64, ARM, ARM64 | `linux-musl-x64`, `linux-musl-arm`, `linux-musl-arm64` |

## Usage

To use these binaries in your project, simply add the NuGet package:

```bash
dotnet package add libgit2
```

## License

This project is licensed under the MIT license (see `LICENSE.md`). The `libgit2` library itself is licensed under a modified GPLv2 with a linking exception (see `libgit2/COPYING`).
