#!/bin/bash
set -e

# Base Build script to do one of: getting sources, building Electronite executable, packaging Electronite as dist.zip
#
# Uses Chromium build tools.
#
# need to set paths before running this script:
#     `export PATH=$(pwd)/depot_tools:$PATH`
#
# to troubleshoot build problems, do build logging by doing `set BUILD_EXTRAS=-vvvvv` before running

ELECTRONITE_REPO="https://github.com/unfoldingWord/electronite"
COMMAND=$1

# Configure environment variables and paths
export PATH=$PATH:~/.electron_build_tools/third_party/depot_tools:~/.electron_build_tools/src
echo "PATH = $PATH"
export GIT_CACHE_PATH=`pwd`/git_cache
mkdir -p "${GIT_CACHE_PATH}"

export DATE=`date`
echo "$DATE" > "./start_time_$1_$2_$DATE.txt"

# sccache no longer supported in Electron
# export SCCACHE_BUCKET="electronjs-sccache"
# export SCCACHE_TWO_TIER=true

export NINJA_STATUS="[%r processes, %f/%t @ %o/s : %es] "
echo "GIT_CACHE_PATH=${GIT_CACHE_PATH}"
echo "SCCACHE_BUCKET=${SCCACHE_BUCKET}"


##########################
# fetch code
##########################
if [ "$COMMAND" == "get" ]; then
  if [ $# -ge 2 ]; then
    BRANCH=$2
  else
    echo "Missing the <ref> to checkout. Please specify a tag or branch name."
    exit 0
  fi

  if [ -d ./src ]; then
    echo "Deleting old work folders in the background. This may take a long time with about 49GB and 850K files."
    mv src src.old
    # run in background
    rm -rf src.old&
  fi  

  # remove cached electronite repo
  FILE=./git_cache/github.com-unfoldingword-electronite
  if [ -d $FILE ]; then
    echo "Removing $FILE"
    rm -rf $FILE
  fi
  FILE=./git_cache/github.com-unfoldingword-electronite.locked
  if [ -d $FILE ]; then
    echo "Removing $FILE"
    rm -f $FILE
  fi

  echo "Fetching code. This can take hours and download over 20GB."
  echo "Checking out $ELECTRONITE_REPO.git@origin/$BRANCH"
  gclient config --name "src/electron" --unmanaged $ELECTRONITE_REPO.git@origin/$BRANCH

  echo "Checking out branch and Applying electronite patches"
  gclient sync --with_branch_heads --with_tags
  
  echo "Identify checked out branch"
  cd src/electron
  git --version
  git status
  git describe --tags
  cd ../..
  
  # save in case graphite patch fails
  export DATE=`date`
  echo "$DATE" > "./end_time_$1_$2_$DATE.txt"

  echo "Applying graphite patches"
  cd ./src
  git apply --whitespace=warn ./electron/docs/development/Electronite/add_graphite_cpp_std_iterator.patch
  cd ..
  
  export DATE=`date`
  echo "$DATE" > "./end_time_$1_$2_$DATE.txt"
  exit 0
fi

##########################
# build release
##########################
if [ "$COMMAND" == "build" ]; then
  if [ $# -ge 2 ]; then
    TARGET=$2
    RELEASE_TARGET="-${TARGET}"
    export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} target_cpu = \"${TARGET}\""
    echo "Building for ${TARGET}"
    if [ "$TARGET" == "arm64" ] && [ "`uname`" == "Linux" ]; then
      export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} fatal_linker_warnings = false enable_linux_installer = false"
    fi
    echo "Building for \"${TARGET}\", extra args: \"${GN_EXTRA_ARGS}\""
  else
    RELEASE_TARGET=""
    echo "Building for default \"x64\", extra args: \"${GN_EXTRA_ARGS}\""
  fi

  echo "Building target: ${RELEASE_TARGET}"

  cd src
  export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools
#  export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} cc_wrapper=\"${PWD}/electron/external_binaries/sccache\""
  echo "Generating configuration..."
  gn gen out/Release${RELEASE_TARGET} --args="import(\"//electron/build/args/release.gn\") $GN_EXTRA_ARGS"
  ninja -C out/Release${RELEASE_TARGET} electron ${BUILD_EXTRAS}
  cd -
  
  export DATE=`date`
  echo "$DATE" > "./end_time_$1_$2_$DATE.txt"
  exit 0
fi

##########################
# create distributable
##########################
if [ "$COMMAND" == "release" ]; then
  if [ $# -ge 2 ]; then
    TARGET="$2"
    RELEASE_TARGET="-${TARGET}"
    STRIP_EXTRA_ARGS=--target-cpu=$TARGET
    export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} target_cpu=\"${TARGET}\""
    echo "Releasing for \"${TARGET}\", extra args: \"${STRIP_EXTRA_ARGS}\""
  else
    RELEASE_TARGET=""
    STRIP_EXTRA_ARGS=""
    echo "Releasing for default \"x64\", extra args: \"${STRIP_EXTRA_ARGS}\""    
  fi

  echo "Releasing: ${RELEASE_TARGET}"

  echo "Creating distributable"
  cd src
  if [ "`uname`" != "Darwin" ]; then
    ./electron/script/strip-binaries.py ${STRIP_EXTRA_ARGS} -d out/Release${RELEASE_TARGET}
  fi
  ninja -C out/Release${RELEASE_TARGET} electron:electron_dist_zip ${BUILD_EXTRAS}
  
  export DATE=`date`
  echo "$DATE" > "./end_time_$1_$2_$DATE.txt"
  exit 0
fi

##########################
# help
##########################
if [ "$COMMAND" == "" ]; then
  echo "***********************
*  Electronite Tools  *
***********************
This is a set of tools for compiling Electronite.
The source for Electronite is at https://github.com/unfoldingWord-dev/electronite.

Usage: ./electronite-tools.sh <command>

where <command> is one of:

    get <ref> - fetches all of the code.
                Where <ref> is a branch or tag.

    build <target> - compiles Electronite, target is optional, defaults to x64,
                       Could be arm64.

    release <target> - creates the distributable.  Use same target as
                       previous build.

For detailed instructions on building Electron
see https://github.com/electron/electron/blob/master/docs/development/build-instructions-gn.md
"
fi
