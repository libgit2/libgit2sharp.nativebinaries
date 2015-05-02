#!/bin/bash

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=OFF \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      ..
cmake --build .

popd

OS=`uname`
ARCH=`uname -m`
 
PACKAGEPATH="nuget.package/libgit2"
LIBEXT="so"

if [ $OS == "Linux" ]; then
	OSPATH="/linux"
	if [ $ARCH == "x86_64" ]; then
		ARCHPATH="/amd64"
	fi
elif [ $OS == "Darwin" ]; then
	OSPATH="/osx"
	LIBEXT="dylib"
else
	OSPATH="/unix"
fi

rm -rf $PACKAGEPATH$OSPATH
mkdir -p $PACKAGEPATH$OSPATH$ARCHPATH

cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH$OSPATH$ARCHPATH

exit $?
