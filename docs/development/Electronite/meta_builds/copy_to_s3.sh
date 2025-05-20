#!/bin/bash
set -e

# Copy electronite builds to S3 storage.  First do cd to build folder before running script. 
#  Only parameter is version.  If AWS keys are not set, will do prompting.
#
# troubleshooting:
#   Got an S3 error that AWS user did not exist when entering credentials at prompts.  
#     No obvious reason for this, but found it started working by either setting or 
#     clearing ID `export AWS_SECRET_ACCESS_KEY=` before running script.
#
# Example `./copy_to_s3.sh v25.3.2`

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
  TARGET=mac
else
  echo "Fallback to Linux"
  TARGET=linux
fi

set -x

# do the s3 copy commands and then exit bash
# presumes to current folder is the build folder
/usr/local/bin/aws s3 cp results/${TARGET}/${VERSION}/arm64/dist.zip s3://electronite-build-data/Electronite/${TARGET}/${VERSION}/arm64/dist.zip
/usr/local/bin/aws s3 cp results/${TARGET}/${VERSION}/x64/dist.zip s3://electronite-build-data/Electronite/${TARGET}/${VERSION}/x64/dist.zip

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
