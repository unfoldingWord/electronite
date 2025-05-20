#!/bin/bash
set -e

# Meta Build script to get sources, and then build for x64 and arm64 by calling build_target_mac.sh
#     for each architecture.  The dist.zip files are stored at $DEST
#
# Uses Electron build tools.
#
# need to set paths before running this script:
#     `export PATH=~/.electron_build_tools/third_party/depot_tools:~/.electron_build_tools/src:$PATH`
#
# to enable goma, do `export GOMA=cache-only` before running script
#
# to troubleshoot build problems, do build logging by doing `export BUILD_EXTRAS=-vvvvv` before running
#
# Example `./build_all_goma_mac.sh electronite-v25.3.2-beta results/mac/v25.3.2`

BRANCH=$1
DEST=$2

echo "Building $BRANCH to: $DEST"

if [ ! -d src ]; then
    echo "Getting sources from $BRANCH"
    ./electronite-tools-goma-3.sh get $BRANCH
fi

TARGET=x64
DEST_FILE=$DEST/$TARGET/dist.zip
if [ -f $DEST_FILE ]; then
    echo "Build $TARGET already exists: $DEST_FILE"
else
    echo "Doing Build $TARGET"
    ./build_target_goma_mac.sh $TARGET $DEST
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
    ./build_target_goma_mac.sh $TARGET $DEST
fi

if [ -f $DEST_FILE ]; then
    echo "Distribution $TARGET built: $DEST_FILE"
else
    echo "Distribution $TARGET failed: $DEST_FILE"
    exit 10
fi

echo "All builds completed to $DEST"
