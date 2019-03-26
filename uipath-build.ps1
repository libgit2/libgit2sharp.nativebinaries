$version =  gc .\libgit2\include\git2\version.h | %{ [regex]::matches($_, '(\d+.\d+.\d+)') } | %{ $_.Groups[1].Value }
.\build.libgit2.ps1
.\buildpackage.ps1 "$version-ssh"