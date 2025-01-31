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
fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

# Проверка, собираем ли для Android
if [[ "$RID" == *"android"* ]]; then
    echo "Building for Android: $RID"
    export ANDROID_TOOLCHAIN_ROOT="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64"
    export android_target_abi=21

    if [[ "$RID" == "android-arm64" ]]; then
        export TOOLCHAIN_FILE="../cmake-toolchains/libgit2-arm64-toolchain.cmake"
    else
        export TOOLCHAIN_FILE="../cmake-toolchains/libgit2-armv7-toolchain.cmake"
    fi

    cmake -DCMAKE_BUILD_TYPE=Release \
          -DUSE_SSH=exec \
          -DLIBGIT2_FILENAME=git2-$SHORTSHA \
          -DUSE_HTTPS=$USEHTTPS \
          -DUSE_BUNDLED_ZLIB=ON \
          -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
          ..

else
    # Сборка для Mac/Linux по умолчанию
    if [[ $OS == "Darwin" ]]; then
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DBUILD_TESTS=OFF \
              -DUSE_SSH=exec \
              -DLIBGIT2_FILENAME=git2-$SHORTSHA \
              -DCMAKE_OSX_ARCHITECTURES=$OSXARCHITECTURE \
              -DUSE_HTTPS=$USEHTTPS \
              -DUSE_BUNDLED_ZLIB=ON \
              ..
    else
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DBUILD_TESTS=OFF \
              -DUSE_SSH=exec \
              -DLIBGIT2_FILENAME=git2-$SHORTSHA \
              -DUSE_HTTPS=$USEHTTPS \
              -DUSE_BUNDLED_ZLIB=ON \
              ..
    fi
fi

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
