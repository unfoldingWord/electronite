## Building Electronite on MacOS
### Setup Build Environment on MacOS Monterey
- Configured using these notes as a reference: [build-instructions-macos](../build-instructions-macos.md)
- Can build on Monterey
- Make sure you have a lot of free disk space - need over 150GB free.
- if you have trouble building with these notes, you could try the older Chromium Build tools: [MacBuildNotesChromeTools](MacBuildNotesChromeTools.md)
- Used xcode 13.3.1

- installed node using nvm
  - install nvm: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash`
  - restart terminal
  - install v16 (had build problems with latest v18):
```
nvm install v16
nvm use v16
node --version
```
- installed homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`
- Installed Python 3.10. Can install using brew `brew install python@3.10`, or download from `https://www.python.org/downloads/` .  Check by `python3 --version` .
- make sure there is a default Python installed by `python --version`. Should report 2.x.x, but If it reports 3.x.x it may work.  Can install 2.7.18 from https://www.python.org/ftp/python/2.7.18/python-2.7.18-macosx10.9.pkg
- configured Python:
```
pip3 install --user --upgrade pip
pip3 install --user pyobjc
pip3 install importlib-metadata
```
- installed build-tools (https://github.com/electron/build-tools). First cd to build folder and run:
``` 
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

### Build Electronite
- first make sure you have downloaded the current version of electronite-tools-3.sh.  There may have been changes from other electronite versions.

#### Build Intel x64
- get the Electronite source code for branch (this can take many hours the first time as the git cache is loaded). Open new terminal window , cd to the build folder and then run:
```
export PATH=$(pwd)/depot_tools:$PATH
./electronite-tools-3.sh get electronite-v25.3.2-beta
```

- Do build (takes a long time)
```
./electronite-tools-3.sh build x64
./electronite-tools-3.sh release x64
```

- Test the build. 
  - Do `cd src/out/Release-x64` and then `open ./Electron.app "https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo"`)
  - Open the developer console by typing`Command-Alt-I`.
  - in console execute `window.location="https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo"`
  - Ensure all the tests pass by visually inspecting the rendered fonts and comparing against the image samples on the site.
  - The example for Padauk from server will not be correct with the triangles.  So need to:
Open elements tab, select body of html, do command-F to search, and search for `padauk_ttf`, and apply attribute `font-feature-settings: "wtri" 1;`.  The triangles should now be rendered correctly.

- The release is at ~/Develop/Electronite-Build/src/out/Release-x64/dist.zip

#### Build Arm64
- if Electronite source already checked out, then skip to `Do build` step:

- get the Electronite source code for branch (this can take many hours the first time as the git cache is loaded):
```
export PATH=$(pwd)/depot_tools:$PATH
./electronite-tools-3.sh get electronite-v25.3.2-beta
```

- Do build (takes a long time)
```
./electronite-tools-3.sh build arm64
./electronite-tools-3.sh release arm64
```

- The release is at ~/Develop/Electronite-Build/src/out/Release-arm64/dist.zip
