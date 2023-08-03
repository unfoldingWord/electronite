#!/bin/bash
set -e

# Meta Build script to get sources, and then build for x64 and arm64 by calling build_target_linux.sh
#     for each architecture.  The dist.zip files are stored at $DEST
#
# Uses Chromium build tools.
#
# need to set paths before running this script:
#     `export PATH=$(pwd)/depot_tools:$PATH`
#
# to troubleshoot build problems, do build logging by doing `export BUILD_EXTRAS=-vvvvv` before running
#
# Example `./build_all_linux.sh electronite-v25.3.2-beta results/linux/v25.3.2`

BRANCH=$1
DEST=$2

echo "Building $BRANCH to: $DEST"

if [ ! -d src ]; then
    echo "Getting sources from $BRANCH"
    ./electronite-tools-3.sh get $BRANCH
fi

TARGET=x64
DEST_FILE=$DEST/$TARGET/dist.zip
if [ -f $DEST_FILE ]; then
    echo "Build $TARGET already exists: $DEST_FILE"
else
    echo "Doing Build $TARGET"
    ./build_target_linux.sh $TARGET $DEST
fi

if [ -f $DEST_FILE ]; then
    echo "Distribution $TARGET built: $DEST_FILE"
else
    echo "Distribution $TARGET failed: $DEST_FILE"
    exit 10
fi

TARGET=arm64
DEST_FILE=$DEST/$TARGET/dist.zip
if [ -f $DEST_FILE ]; then
    echo "Build $TARGET already exists: $DEST_FILE"
else
    echo "Doing Build $TARGET"
    cd ./src
    build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
    cd ..

    ./build_target_linux.sh $TARGET $DEST
fi

if [ -f $DEST_FILE ]; then
    echo "Distribution $TARGET built: $DEST_FILE"
else
    echo "Distribution $TARGET failed: $DEST_FILE"
    exit 10
fi

echo "All builds completed to $DEST"