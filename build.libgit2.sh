#!/bin/bash

set -e

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}
OS=`uname`
ARCH=`uname -m`
PACKAGEPATH="nuget.package/runtimes"

if [[ $OS == "Darwin" ]]; then
	USEHTTPS="ON"
elif [[ $OS == "MINGW32"* ]]; then
	USEHTTPS="WinHTTP"
	ARCH="x86"
elif [[ $OS == "MINGW64"* ]]; then
	USEHTTPS="WinHTTP"
	ARCH="x86_64"
else
	USEHTTPS="OFF"
fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

if [[ $RID == *arm ]]; then
	export TOOLCHAIN_FILE=/nativebinaries/CMakeLists.arm.txt
fi

if [[ $RID == *arm64 ]]; then
	export TOOLCHAIN_FILE=/nativebinaries/CMakeLists.arm64.txt
fi

if [[ $OS == "MINGW"* ]]; then
	export CMAKE_GENERATOR="MSYS Makefiles"
fi

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=OFF \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      -DUSE_HTTPS=$USEHTTPS \
      -DUSE_BUNDLED_ZLIB=ON \
      -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} \
      ..
cmake --build .

popd

if [[ $OS == "MINGW"* ]]; then
	RID_PREFIX="win"
else
	RID_PREFIX="unix"
fi

if [[ $RID == "" ]]; then
	if [[ $ARCH == "x86_64" ]]; then
		RID="$RID_PREFIX-x64"
	else
		RID="$RID_PREFIX-x86"
	fi
	echo "$(tput setaf 3)RID not defined. Falling back to '$RID'.$(tput sgr0)"
fi

if [[ $OS == "Darwin" ]]; then
	LIBEXT="dylib"
elif [[ $OS == "MINGW"* ]]; then
	LIBEXT="dll"
else
	LIBEXT="so"
fi

rm -rf $PACKAGEPATH/$RID
mkdir -p $PACKAGEPATH/$RID/native

if [[ $OS == "MINGW"* ]]; then
	cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native/git2-$SHORTSHA.$LIBEXT
else
	cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native
fi
