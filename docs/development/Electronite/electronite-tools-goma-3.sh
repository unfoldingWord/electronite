#!/bin/bash
set -e
set -x

# Base Build script to do one of: getting sources, building Electronite executable, packaging Electronite as dist.zip
#
# Uses Electron build tools.
#
# need to set paths before running this script:
#     `export PATH=~/.electron_build_tools/third_party/depot_tools:~/.electron_build_tools/src:$PATH`
#
# to enable goma, do `export GOMA=cache-only` before running script
#
# to troubleshoot build problems, do build logging by doing `set BUILD_EXTRAS=-vvvvv` before running

FORK="unfoldingWord/electronite"
ELECTRONITE_REPO="https://github.com/$FORK"
COMMAND=$1

# Configure environment variables and paths
# export PATH=$PATH:~/.electron_build_tools/third_party/depot_tools:~/.electron_build_tools/src
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

if [ "${GOMA}" == "" ]; then
  GOMA=none
  echo "GOMA defaulting to ${GOMA}"
else
  echo "GOMA is set to ${GOMA}"
fi

echo "OS type ${OSTYPE}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Linux Detected"
  SED_INPLACE=-i.orig
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "MacOS Detected"
  SED_INPLACE="-I .orig"
else
  echo "Other Detected"
  SED_INPLACE=-i.orig
fi
echo "using SED_INPLACE of ${SED_INPLACE}"

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
  # clear old configs
  CONFIG_FILE=~/.electron_build_tools/configs/evm.x64.json
  rm -f ${CONFIG_FILE}
  rm -f  ./.gclient

  e init --root=. -o x64 x64 -i release --goma cache-only --fork ${FORK} --use-https -f
  
  # add branch to fork
  sed ${SED_INPLACE} "s|${FORK}.git|${FORK}.git@origin/${BRANCH}|g" ${CONFIG_FILE}
  sed ${SED_INPLACE} "s|https://github.com/electron/electron|https://github.com/${FORK}.git@origin/${BRANCH}|g" ./.gclient

  echo "Checking out branch and Applying electronite patches"
  e sync
  
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
    echo "Building for \"${TARGET}\""
  else
    echo "Building for default \"x64\""
    TARGET=x64
  fi

  CONFIG_FILE=~/.electron_build_tools/configs/evm.$TARGET.json
  RELEASE_TARGET="-${TARGET}"
  e init --root=. -o $TARGET $TARGET -i release --goma $GOMA --fork ${FORK} --use-https -f
  # add target architecture to config
  sed ${SED_INPLACE} 's|release.gn\\")"|release.gn\\")", "target_cpu = \\"'"$TARGET"'\\""|g' ${CONFIG_FILE}

  echo "Building Electronite..."  
  e build electron
  
  export DATE=`date`
  echo "$DATE" > "./end_time_$1_$2_$DATE.txt"
  exit 0
fi

##########################
# create distributable
##########################
if [ "$COMMAND" == "release" ]; then
  if [ $# -ge 2 ]; then
    TARGET=$2
    STRIP_EXTRA_ARGS=--target-cpu=$TARGET
    echo "Releasing for \"${TARGET}\", extra args: \"${STRIP_EXTRA_ARGS}\""
  else
    TARGET=x64
    STRIP_EXTRA_ARGS=""
    echo "Releasing for default \"x64\", extra args: \"${STRIP_EXTRA_ARGS}\""
  fi
  
  echo "Releasing: ${RELEASE_TARGET}"

  CONFIG_FILE=~/.electron_build_tools/configs/evm.$TARGET.json
  RELEASE_TARGET="-${TARGET}"
  e init --root=. -o $TARGET $TARGET -i release --goma $GOMA --fork ${FORK} --use-https -f
  # add target architecture to config
  sed ${SED_INPLACE} 's|release.gn\\")"|release.gn\\")", "target_cpu = \\"'"$TARGET"'\\""|g' ${CONFIG_FILE}

  if [ "`uname`" != "Darwin" ]; then
    echo "Removing symbols for Linux..."
    cd src
    ./electron/script/strip-binaries.py ${STRIP_EXTRA_ARGS} -d out/${TARGET}
    cd ..
  fi

  echo "Creating Electronite Distributable..."
  e build electron:dist
  
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
