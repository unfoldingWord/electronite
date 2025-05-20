## Building Electronite on Linux
### Setup Build Envirnonment on Clean Linux VM
- Configured my VM using these notes as a reference: [build-instructions-linux](../build-instructions-linux.md)
- Make sure the VM has a lot of disk space - I ran out of disk space with 60GB of storage configured.  Rather than starting over with a new VM.  I added a second Virtual Hard Drive with 100GB and then used that drive for the builds.
- to create `arm64` and `arm` builds, you must have installed the arm dependencies mentioned in the Linux build instructions above.  Then run:
- Make sure you have a valid python3.  Check by `python3 --version` .
- make sure there is a default Python installed by `python --version`.  Should report 2.x.x, but If it reports 3.x.x it may work.

- use node v16 (had build problems with latest v18)
- installed build-tools (https://github.com/electron/build-tools). First cd to build folder and run:
``` 
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```
- note 32-bit builds for Linux no longer supported.

### Build Electronite
- first make sure you have downloaded the current version of electronite-tools-3.sh.  There may have been changes from other electronite versions.

#### Build x64
- get the Electronite source code for branch (this can take many hours the first time as the git cache is loaded). Open new terminal window, cd to the build folder and then run:
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
    - Do `cd src/out/Release-x64` and then `./electron "https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo"` .
    - Open the developer console by typing`Control-Shift-I`.
    - if it didn't open to test page, then in console execute `window.location="https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo"`
    - Ensure all the tests pass by visually inspecting the rendered fonts and comparing against the image samples on the site.
    - The example for Padauk from server will not be correct with the triangles.  So need to:
      Open elements tab, select body of html, do Control-F to search, and search for `padauk_ttf`, and apply attribute `font-feature-settings: "wtri" 1;`.  The triangles should now be rendered correctly.

- The release is at ~/Develop/Electronite-Build/src/out/Release-x64/dist.zip

#### Build Arm64
- open terminal and initialize build configuration (note that if you have a slow or unreliable internet connection, it is better to change the goma setting from `cache-only` to `none`):
```
sudo apt-get install binutils-aarch64-linux-gnu
```

- if Electronite source already checked out, then skip to `Build Init` step.

- get the Electronite source code for branch (this can take many hours the first time as the git cache is loaded):
```
export PATH=$(pwd)/depot_tools:$PATH
./electronite-tools-3.sh get electronite-v25.3.2-beta
```

- Build Init: to create `arm64` builds, you must have installed the arm64 dependencies mentioned in the Linux build instructions above.  Then run:
```
cd ./src
build/linux/sysroot_scripts/install-sysroot.py --arch=arm64
cd ..
```

- Do build (takes a long time)
```
./electronite-tools-3.sh build arm64
./electronite-tools-3.sh release arm64
```

- The release is at ~/Develop/Electronite-Build/src/out/Release-arm64/dist.zip
