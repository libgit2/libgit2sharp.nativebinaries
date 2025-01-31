#!/bin/bash

export build_root=$HOME/libsbuild
mkdir -p $build_root
cd $build_root

echo "Downloading: Android SDK"
# ANDROID_HOME is android sdk root, is sdk root, not ndk root
export TOOLS=$build_root/tools
export ANDROID_CMD_TOOLS=$TOOLS/android-cmdline-tools
export ANDROID_HOME=$build_root/android-sdk
export CMAKE_VERSION=3.31.1
export NDK_VERSION=26.3.11579264

mkdir -p $ANDROID_CMD_TOOLS
mkdir -p $ANDROID_HOME
curl -L -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

rm -rf $ANDROID_CMD_TOOLS

unzip cmdline-tools.zip -d $TOOLS/
mv $TOOLS/cmdline-tools $ANDROID_CMD_TOOLS
export ANDROID_SDKMANAGER=$ANDROID_CMD_TOOLS/bin/sdkmanager
chmod +x $ANDROID_SDKMANAGER
echo "install cmake by Android sdkmanager"
yes | $ANDROID_SDKMANAGER --install "cmake;$CMAKE_VERSION" --sdk_root=$ANDROID_HOME
# $ANDROID_HOME/cmdline-tools/bin/sdkmanager --list --sdk_root=$ANDROID_HOME
# cmake root dir
export CMAKE_DIR=$ANDROID_HOME/cmake/$CMAKE_VERSION
# cmake 
export CMAKE_PATH=$CMAKE_DIR/bin/cmake

echo "print cmake version"
$CMAKE_PATH --version

echo "downloading android ndk..."
# channel 0 stable, 1 beta, 3 canary, see: https://github.com/android/ndk-samples/wiki/Configure-NDK-Path#the-sdkmanager-command-line-tool
yes | $ANDROID_SDKMANAGER --channel=0 --install "ndk;$NDK_VERSION" --sdk_root=$ANDROID_HOME

echo "set sdk.dir to local.properties for gradle"
REPO_PATH=${1:-$GITHUB_WORKSPACE}
REPO_PATH=${REPO_PATH:-/home/runner/work/libgit2sharp.nativebinaries/libgit2sharp.nativebinaries}
LOCAL_PROPERTIES_PATH=$REPO_PATH/local.properties
echo -e "\nsdk.dir=$ANDROID_HOME" >> $LOCAL_PROPERTIES_PATH
echo "local.properties at: $LOCAL_PROPERTIES_PATH"
echo "cat local.properties:"
cat $LOCAL_PROPERTIES_PATH


echo "Installation complete"
