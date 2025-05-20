#!/bin/bash
set -e

# Build script to do build build and release for $TARGET if not present at $DEST
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
# Example `./build_target_goma_linux.sh x64 results/linux/v25.3.2`

TARGET=$1
DEST=$2

echo "Building $TARGET to: $DEST"

BUILD_TARGET=./src/out/$TARGET/electron
if [ -f $BUILD_TARGET ]; then
    echo "Build Target already exists: $BUILD_TARGET"
else
    echo "Doing Build $TARGET to $BUILD_TARGET"
    ./electronite-tools-goma-3.sh build $TARGET
    echo "Finished Build $TARGET to $BUILD_TARGET"
fi

if [ -f $BUILD_TARGET ]; then
    echo "Target built: $BUILD_TARGET"
else
    echo "Target failed: $BUILD_TARGET"
    exit 1
fi

RELEASE_TARGET=./src/out/$TARGET/dist.zip
if [ -f $RELEASE_TARGET ]; then
    echo "Release Target already exists: $RELEASE_TARGET"
else
    echo "Doing Release $TARGET"
    ./electronite-tools-goma-3.sh release $TARGET
fi

if [ -f $RELEASE_TARGET ]; then
    echo "Target released: $RELEASE_TARGET"
else
    echo "Target failed: $RELEASE_TARGET"
    exit 1
fi

DEST_FOLDER=$DEST/$TARGET
if [ -d $DEST_FOLDER ]; then
    echo "Destination exists: $DEST_FOLDER"
else
    echo "Creating Destination folder: $DEST_FOLDER"
    mkdir -p $DEST_FOLDER
fi

if [ -d $DEST_FOLDER ]; then
    echo "Destination exists: $DEST_FOLDER"
else
    echo "Error Creating Destination folder: $DEST_FOLDER"
    exit 1
fi


DEST_FILE=$DEST_FOLDER/dist.zip
echo "Copy from $RELEASE_TARGET to $DEST_FILE"
cp $RELEASE_TARGET $DEST_FILE
if [ -f $DEST_FILE ]; then
    echo "Target copied: $DEST_FILE"
else
    echo "Error moving dist.zip file to: $DEST_FILE"
    exit 1
fi

TARGET_FOLDER=./src/out/$TARGET
echo "Remove $TARGET_FOLDER to free up space for later builds"
rm -rf $TARGET_FOLDER
if [ -d $TARGET_FOLDER ]; then
    echo "Error removing $TARGET_FOLDER"
    exit 1
fi

echo "Done copying build to $TARGET_FOLDER"
