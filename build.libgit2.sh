#!/bin/bash

set -e

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}
OS=`uname`
ARCH=`uname -m`
PACKAGEPATH="nuget.package/runtimes"
OSXARCHITECTURE=$ARCH

if [[ $OS == "Darwin" ]]; then
    USEHTTPS="ON"
    if [[ $RID == "osx-arm64" ]]; then
        OSXARCHITECTURE="arm64"
    elif [[ $RID == "osx-x64" ]]; then
        OSXARCHITECTURE="x86_64"
    fi
else
    USEHTTPS="OpenSSL-Dynamic"
    if [[ $RID == android-* ]]; then
        if [[ $NDK_PATH == "" ]]; then
            echo "NDK_PATH not found"
            exit 0
        fi

        CMAKE_MAKEFILES="-G=Unix Makefiles"
        CMAKE_ANDROID=" -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake -DANDROID_PLATFORM=android-24 -DANDROID_ABI="
        if [[ $RID == "android-arm64" ]]; then
            CMAKE_ANDROID=$CMAKE_ANDROID"arm64-v8a"
        else 
            CMAKE_ANDROID=$CMAKE_ANDROID"armeabi-v7a"
        fi
        echo $CMAKE_ANDROID
    fi
fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_TESTS:BOOL=OFF \
      -DUSE_SSH=ON \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES=$OSXARCHITECTURE \
      -DUSE_HTTPS=$USEHTTPS \
      -DUSE_BUNDLED_ZLIB=ON \
      "$CMAKE_MAKEFILES" \
      $CMAKE_ANDROID \
      ..
cmake --build .

popd

if [[ $RID == "" ]]; then
    echo "$(tput setaf 3)RID not defined. Skipping copy to package path.$(tput sgr0)"
    exit 0
fi

if [[ $OS == "Darwin" ]]; then
    LIBEXT="dylib"
else
    LIBEXT="so"
fi

rm -rf $PACKAGEPATH/$RID
mkdir -p $PACKAGEPATH/$RID/native

cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native
