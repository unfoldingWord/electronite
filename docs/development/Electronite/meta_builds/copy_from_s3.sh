#!/bin/bash
set -e

# Copy electronite builds to S3 storage.  First do cd to build folder before running script. 
#  Only parameter is VERSION.  If AWS keys are not set, will do prompting.
#
# troubleshooting:
#   Got an S3 error that AWS user did not exist when entering credentials at prompts.  
#     No obvious reason for this, but found it started working by either setting or 
#     clearing ID `export AWS_SECRET_ACCESS_KEY=` before running script.
#
# Example `./copy_from_s3.sh v25.3.2`

VERSION=$1

echo "Copying Electronite builds for VERSION to S3"

# turn off history
set +o history

# set AWS Keys in environment variables
if [ "$AWS_ACCESS_KEY_ID" == "" ]; then
  read -p "Enter AWS_ACCESS_KEY_ID: " KEY_ID
  export AWS_ACCESS_KEY_ID=$KEY_ID
fi
if [ "$AWS_SECRET_ACCESS_KEY" == "" ]; then
  read -p "Enter AWS_SECRET_ACCESS_KEY: " ACCESS_KEY
  export AWS_SECRET_ACCESS_KEY=$ACCESS_KEY
fi

if [ "`uname`" == "Darwin" ]; then
  echo "Detected Mac"
else
  echo "Fallback to Linux"
fi

set -x

copy_from_s3 ()
{
  VERSION_=$1
  OS=$2
  ARCH=$3
  
  OS_DEST=$OS
  if [ "$OS" == "mac" ]; then
    OS_DEST=darwin
  elif [ "$OS" == "win" ]; then
    OS_DEST=win32     
  fi
  
  ARCH_DEST=$ARCH
  if [ "$ARCH" == "x86" ]; then
    ARCH_DEST=ia32   
  fi
  
  echo "Copying from $OS/$ARCH to $OS_DEST/$ARCH_DEST"
  /usr/local/bin/aws s3 cp s3://electronite-build-data/Electronite/${OS}/${VERSION_}/${ARCH}/dist.zip  ./electronite-${VERSION_}-graphite-beta-${OS_DEST}-${ARCH_DEST}.zip
}

# do the s3 copy commands and then exit bash
# presumes to current folder is the build folder
TARGET=mac
copy_from_s3 $VERSION mac x64
copy_from_s3 $VERSION mac arm64

TARGET=win
copy_from_s3 $VERSION win x64
copy_from_s3 $VERSION win x86
copy_from_s3 $VERSION win arm64

TARGET=linux
copy_from_s3 $VERSION linux x64
copy_from_s3 $VERSION linux arm64

set +x

if [ "$KEY_ID" != "" ]; then
  echo "Clearing temp AWS_ACCESS_KEY_ID"
  export AWS_ACCESS_KEY_ID=
fi

if [ "$ACCESS_KEY" != "" ]; then
  echo "Clearing temp AWS_SECRET_ACCESS_KEY"
  export AWS_SECRET_ACCESS_KEY=
fi

echo "All copies completed to $VERSION"
