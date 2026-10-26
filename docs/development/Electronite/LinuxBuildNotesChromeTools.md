## Building Electronite on Linux
### Setup on Linux VM
- Configured my VM using these notes as a reference: [build-instructions-linux](../build-instructions-linux.md){
- Make sure the VM has a lot of disk space - I ran out of disk space with 60GB of storage configured.  Rather than starting over with a new VM.  I added a second Virtual Hard Drive with 100GB and then used that drive for the builds.

### Build Electronite
- open terminal and cd to the folder you will use for build
- install the depot_tools here: `git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git`
- download build script to this folder from: [electronite-tools](electronite-tools.sh)
- set execute permission on script: `chmod +x ./electronite-tools.sh`
- before build do: `export PATH=/path/to/depot_tools:$PATH`
- get source files (this can take several hours the first time as the git cache is loaded): `./electronite-tools.sh get <<build-tag>>`
- to create `arm64` builds, you must have installed the arm64 dependencies mentioned in the Linux build instructions above.  After doing `e sync` run:
```
cd electron-gn/src
build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
cd ../..
```
- to create `arm` builds, you must have installed the arm dependencies mentioned in the Linux build instructions above.  After doing `e sync` run:
```
cd electron-gn/src
build/linux/sysroot_scripts/install-sysroot.py --arch=arm
cd ../..
```
- builds can take over 20 hours on a VM.
- build Electronite for Intel 64-bit:
    - build for 64-bit: `./electronite-tools.sh build x64`
    - create release for 64-bit: `./electronite-tools.sh release x64`

- build Electronite for Intel 32-bit:
    - initialize build configuration: `sudo apt-get install ia32-libs-gtk ia32-libs`
    - build for 32-bit: `./electronite-tools.sh build x86`
    - create release for 32-bit: `./electronite-tools.sh release x86`

- build Electronite for Arm 64-bit:
    - build for arm 64-bit: `./electronite-tools.sh build arm64`
    - create release for arm 64-bit: `./electronite-tools.sh release arm64`

- build Electronite for Arm:
    - build for arm: `./electronite-tools.sh build arm`
    - create release for arm: `./electronite-tools.sh release arm`
   