#!/bin/bash

set -e

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}
OS=`uname`
PACKAGEPATH="nuget.package/runtimes"

if [[ $OS == "Darwin" ]]; then
	USEHTTPS="ON"
else
	USEHTTPS="OpenSSL-Dynamic"
fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=OFF \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES="x86_64" \
      -DUSE_HTTPS=$USEHTTPS \
      -DUSE_BUNDLED_ZLIB=ON \
      ..
cmake --build . --config Release

popd

if [[ $OS == "Darwin" ]]; then
	LIBEXT="dylib"
else
	LIBEXT="so"
fi

rm -rf $PACKAGEPATH/$RID
mkdir -p $PACKAGEPATH/$RID/native

cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native
