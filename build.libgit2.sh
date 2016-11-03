#!/bin/bash

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}

if [ $OS == "Darwin" ]; then

rm -rf libssh2/build
mkdir libssh2/build
pushd libssh2/build

export _BINPATH=`pwd`

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DCMAKE_C_FLAGS=-fPIC \
      -DBUILD_SHARED_LIBS=OFF \
	  -DENABLE_ZLIB_COMPRESSION=ON \
	  -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      ..
cmake --build .

popd

fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

if [ $OS == "Darwin" ]; then
cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=ON \
	  -DLIBSSH2_FOUND=ON \
	  -DLIBSSH2_LIBRARIES=$TRAVIS_BUILD_DIR/libssh2/build/src/libssh2.a \
	  -DLIBSSH2_INCLUDE_DIRS=$TRAVIS_BUILD_DIR/libssh2/include \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-ssh-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      ..
else
cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=ON \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-ssh-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      ..
fi
cmake --build .

popd

OS=`uname`
ARCH=`uname -m`
 
PACKAGEPATH="nuget.package/libgit2"
LIBEXT="so"

if [ $OS == "Linux" ]; then
	if [ "$ARCH" == "x86_64" ]; then
		ARCH="x64"
	fi

	OSPATH="/linux"
	ARCHPATH="-$ARCH"
elif [ $OS == "Darwin" ]; then
	OSPATH="/osx"
	LIBEXT="dylib"
else
	OSPATH="/unix"
fi

rm -rf $PACKAGEPATH$OSPATH
mkdir -p $PACKAGEPATH$OSPATH$ARCHPATH/native

cp libgit2/build/libgit2-ssh-$SHORTSHA.$LIBEXT $PACKAGEPATH$OSPATH$ARCHPATH/native

exit $?
