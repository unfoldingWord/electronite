#!/bin/bash
set -e
set -x

# script to get electron tag ($NEW_ELECTRON_VERSION) from upstream, make 
#        both a new electron branch and a new electronite branch.
#    Then copy files from old electronite branch ($OLD_ELECTRONITE_BRANCH)
#        and commit them in new electronite branch.
#
# Example `./make_new_electronite.sh v25.3.2 electronite-v23.3.10`
#
# or with github token:
#   `./make_new_electronite.sh v25.3.2 electronite-v23.3.10 <token>`

NEW_ELECTRON_VERSION=$1
OLD_ELECTRONITE_BRANCH=$2
CREDS=$3

# get files from previous version
git fetch --all
git checkout $OLD_ELECTRONITE_BRANCH
git pull
mkdir -p ./temp_files/Electronite
cp -R ./docs/development/Electronite ./temp_files
cp patches/chromium/add_graphite.patch temp_files/add_graphite.patch

# Get all upstream tags
git fetch --force --tags upstream

# push up the new electron tag
if [ "${CREDS}" == "" ]; then
  git push --no-verify origin $NEW_ELECTRON_VERSION
else # use passed credentials
  git push --no-verify https://${CREDS}@github.com/unfoldingWord/electronite.git $NEW_ELECTRON_VERSION
fi

# get the source electron tag
git checkout $NEW_ELECTRON_VERSION
# create a new electron branch from electron sources
git checkout -b ${NEW_ELECTRON_VERSION}-electron
# push it up
if [ "${CREDS}" == "" ]; then
  git push --no-verify origin ${NEW_ELECTRON_VERSION}-electron
else # use passed credentials
  git push --no-verify  https://${CREDS}@github.com/unfoldingWord/electronite.git
fi

# create a new Electronite branch from electron sources
git checkout -b electronite-${NEW_ELECTRON_VERSION}-beta

# copy files from previous version
mkdir -p ./docs/development/Electronite
cp -R ./temp_files/Electronite ./docs/development
cp temp_files/add_graphite.patch patches/chromium/add_graphite.patch 

# add new files to commit
git add docs/development/Electronite/
git add patches/chromium/add_graphite.patch
rm -rf ./temp_files

# get latest electron.d.ts
curl -LJOH 'Accept: application/octet-stream'  https://github.com/electron/electron/releases/download/${NEW_ELECTRON_VERSION}/electron.d.ts

# convert to electronite and add it to repo
sed "s/'electron/'electronite/g" electron.d.ts > electron.d.ts.new
cp electron.d.ts.new ./docs/development/Electronite/electron.d.ts
git add -f docs/development/Electronite/electron.d.ts
rm electron.d.ts electron.d.ts.new

if [ "${CREDS}" == "" ]; then
  git push --no-verify origin electronite-${NEW_ELECTRON_VERSION}-beta
else # use passed credentials
  git push --no-verify https://${CREDS}@github.com/unfoldingWord/electronite.git electronite-${NEW_ELECTRON_VERSION}-beta
fi

