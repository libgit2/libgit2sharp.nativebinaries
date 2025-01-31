#!/bin/bash

set -e

# OPTIONAL: Install required packages (uncomment if needed)
# sudo apt-get update
# sudo apt-get install -y curl unzip

BUILD_ROOT="$HOME/puppylibsbuild"
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

# Paths and versions
TOOLS="$BUILD_ROOT/tools"
ANDROID_CMD_TOOLS="$TOOLS/android-cmdline-tools"
ANDROID_HOME="$BUILD_ROOT/android-sdk"
CMAKE_VERSION="3.31.1"
NDK_VERSION="26.3.11579264"

# Create directories
mkdir -p "$ANDROID_CMD_TOOLS"
mkdir -p "$ANDROID_HOME"

echo "Downloading Android command line tools..."
curl -L -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

# Unzip and move to the final location
unzip cmdline-tools.zip -d "$TOOLS/"
mv "$TOOLS/cmdline-tools" "$ANDROID_CMD_TOOLS"

# Define sdkmanager path
ANDROID_SDKMANAGER="$ANDROID_CMD_TOOLS/bin/sdkmanager"
chmod +x "$ANDROID_SDKMANAGER"

echo "Installing CMake $CMAKE_VERSION via sdkmanager..."
yes | "$ANDROID_SDKMANAGER" --install "cmake;$CMAKE_VERSION" --sdk_root="$ANDROID_HOME"

# Path to the installed CMake
CMAKE_DIR="$ANDROID_HOME/cmake/$CMAKE_VERSION"
CMAKE_PATH="$CMAKE_DIR/bin/cmake"

echo "CMake version:"
"$CMAKE_PATH" --version

echo "Installing NDK $NDK_VERSION..."
yes | "$ANDROID_SDKMANAGER" --channel=0 --install "ndk;$NDK_VERSION" --sdk_root="$ANDROID_HOME"

echo "NDK installation complete."

# OPTIONAL: If you need to automatically set environment variables for subsequent steps,
# you can echo them into $GITHUB_ENV or similar:
# echo "ANDROID_HOME=$ANDROID_HOME" >> $GITHUB_ENV
# echo "ANDROID_NDK=$ANDROID_HOME/ndk/$NDK_VERSION" >> $GITHUB_ENV

echo "All done."
