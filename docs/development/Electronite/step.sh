#!/bin/bash
set -e

# show commands as they are executed
set -x

ELECTRONITE_REPO="https://github.com/unfoldingWord/electronite"
COMMAND=$1

# Configure environment variables and paths
export GIT_CACHE_PATH=`pwd`/git_cache
mkdir -p "${GIT_CACHE_PATH}"

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

  echo "Deleting old work folders. This may take a long time with about 49GB and 850K files."
  rm -rf electron-gn
  mkdir -p electron-gn
  cd electron-gn
  echo "Fetching code. This will take a long time and download up to 16GB."
  gclient config --name "src/electron" --unmanaged $ELECTRONITE_REPO
  gclient sync --with_branch_heads --with_tags --nohooks --noprehooks
  cd src/electron
  echo "Checking out $BRANCH"
  git checkout $BRANCH
  cd -
  echo "Applying electron patches"
  gclient sync --with_branch_heads --with_tags
  exit 0
fi

##########################
# build release
##########################
if [ "$COMMAND" == "build" ]; then
  if [ $# -ge 2 ]; then
    TARGET=$2
    RELEASE_TARGET="-${TARGET}"
    export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} target_cpu=\"${TARGET}\""
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

  cd electron-gn/src
  export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools
#  export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} cc_wrapper=\"${PWD}/electron/external_binaries/sccache\""
  echo "Generating configuration..."
  gn gen out/Release${RELEASE_TARGET} --args="import(\"//electron/build/args/release.gn\") $GN_EXTRA_ARGS"
  ninja -C out/Release${RELEASE_TARGET} electron
  cd -
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
  cd electron-gn/src
  if [ "`uname`" != "Darwin" ]; then
    ./electron/script/strip-binaries.py ${STRIP_EXTRA_ARGS} -d out/Release${RELEASE_TARGET}
  fi
  ninja -C out/Release${RELEASE_TARGET} electron:electron_dist_zip
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