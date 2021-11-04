#!/bin/bash

set -e

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}
OS=`uname`
ARCH=`uname -m`
PACKAGEPATH="nuget.package/runtimes"
OSXARCHITECTURE="x86_64"

if [[ $OS == "Darwin" ]]; then
	USEHTTPS="ON"
	if [[ $ARCH == "arm64" ]]; then
		OSXARCHITECTURE="arm64"
	fi
else
	USEHTTPS="OpenSSL-Dynamic"
fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=OFF \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES=$OSXARCHITECTURE \
      -DUSE_HTTPS=$USEHTTPS \
      -DUSE_BUNDLED_ZLIB=ON \
      ..
cmake --build .

popd

if [[ $RID == "" ]]; then
	if [[ $ARCH == "x86_64" ]]; then
		RID="unix-x64"
	else
		RID="unix-x86"
	fi
	echo "$(tput setaf 3)RID not defined. Falling back to '$RID'.$(tput sgr0)"
fi

if [[ $OS == "Darwin" ]]; then
	LIBEXT="dylib"
else
	LIBEXT="so"
fi

rm -rf $PACKAGEPATH/$RID
mkdir -p $PACKAGEPATH/$RID/native

cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native
