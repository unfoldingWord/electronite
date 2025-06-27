## Building Electronite on Windows
### Setup on Clean Windows 10 VM
- Configured my VM using these notes as a reference:
    - https://chromium.googlesource.com/chromium/src/+/main/docs/windows_build_instructions.md#visual-studio
    - [build-instructions-windows](../build-instructions-windows.md)
- Make sure the VM has a lot of disk space - I ran out of disk space with 120GB of storage configured.  Rather than starting over with a new VM.  I added a second Virtual Hard Drive with 100GB and then used that drive for the builds.
- Make sure to add exception to the build folder for Windows defender, or it will delete a couple of the build files.
- Add to git support for long file names: `git config --system core.longpaths true`
- Installed VS 2019 Community edition and Windows SDK 10.0.19041.0.
- Installed Python 3.9.11 (Python 3.10 has breaking changes that broke compile) from https://www.python.org/downloads/windows/
- configured Python:
```
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install pywin32
```
- installed node
- Added environment variables:
```
vs2019_install=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
WINDOWSSDKDIR=C:\Program Files (x86)\Windows Kits\10
```

### Build Electronite
- _**Note:** Use command prompt, not powershell as it will cause problems._
- cd to the folder you will use for build
- unzip the depot_tools here
- download build script to this folder from: [electronite-tools](electronite-tools.bat)
- before build do: `set PATH=%cd%\depot_tools;%PATH%`
- get source files (this can take several hours the first time as the git cache is loaded): `.\electronite-tools.bat get <<build-tag>>`
- builds can take over 20 hours on a VM.
- build Electronite for 32-bit Windows:
    - build for 32-bit: `.\electronite-tools.bat build x86`
    - create release for 32-bit: `.\electronite-tools.bat release x86`
- build Electronite for 64-bit Windows:
    - build for 64-bit: `.\electronite-tools.bat build x64`
    - create release for 64-bit: `.\electronite-tools.bat release x64`

