## Building Electronite on MacOS
### Setup on MacOS Catalina VM
- Configured my VM using these notes as a reference: [build-instructions-macos](../build-instructions-macos.md)
- Make sure the VM has a lot of disk space - I was able to build with 120GB of storage configured.  But only had 13GB of space at end of build, so that may not be enough in the future.
- Installed xcode 12.4.
- installed node using nvm
    - install nvm: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash`
    - restart terminal
    - install latest node:
```
nvm install --lts
nvm use --lts
node --version
```
- installed homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`
- Installed Python 3.9 (Python 3.10 has breaking changes that broke compile) `brew install python@3.9`
- configured Python:
```
pip3 install --user --upgrade pip
pip3 install --user pyobjc
```

### Build Electronite
- open terminal and cd to the folder you will use for build
- install the depot_tools here: `git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git`
- download build script to this folder from: [electronite-tools](electronite-tools.sh)
- set execute permission on script: `chmod +x ./electronite-tools.sh`
- before build do: `export PATH=/path/to/depot_tools:$PATH`
- get source files (this can take several hours the first time as the git cache is loaded): `./electronite-tools.sh get <<build-tag>>`
- builds can take over 15 hours on a VM.
- build Electronite for MacOS Intel 64-bit:
    - build for 64-bit: `./electronite-tools.sh build x64`
    - create release for 32-bit: `./electronite-tools.sh release x64`
- build Electronite for MacOS Arm 64-bit:
    - build for arm 64-bit: `./electronite-tools.sh build arm64`
    - create release for arm 64-bit: `./electronite-tools.sh release arm64`

