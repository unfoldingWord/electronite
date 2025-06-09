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
# Example `./build_all_linux.sh electronite-v35.5.1-beta results/linux/v35.5.1`

BRANCH=$1
DEST=$2

echo "Building $BRANCH to: $DEST"

if [ ! -d src ]; then
    echo "Getting sources from $BRANCH"
    # make sure to get arm64 sources also
     export GCLIENT_EXTRA_ARGS="--custom-var=checkout_arm64=True"
     echo "GCLIENT_EXTRA_ARGS=${GCLIENT_EXTRA_ARGS}"
    ./electronite-tools-3.sh get $BRANCH
fi

TARGETS=("x64" "arm64")

for TARGET in "${TARGETS[@]}"; do
    DEST_FILE=$DEST/$TARGET/dist.zip
    if [ -f $DEST_FILE ]; then
        echo "Build $TARGET already exists: $DEST_FILE"
        continue
    fi

    echo "Doing Build $TARGET"
    ./build_target_linux.sh $TARGET $DEST

    if [ -f $DEST_FILE ]; then
        echo "Distribution $TARGET built: $DEST_FILE"
    else
        echo "Distribution $TARGET failed: $DEST_FILE"
        exit 10
    fi
done

echo "All builds completed to $DEST"