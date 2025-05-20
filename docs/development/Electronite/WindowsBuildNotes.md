## Building Electronite on Windows
### Setup Build Environment on Clean Windows 10 VM
- Configured my VM using these notes as a reference:
  - https://chromium.googlesource.com/chromium/src/+/main/docs/windows_build_instructions.md#visual-studio
  - [build-instructions-windows](../build-instructions-windows.md)
- Make sure the VM has a lot of disk space - I configured with 220GB of storage.
- if you have trouble building with these notes, you could try the older Chromium Build tools: [WindowsBuildNotesChromeTools](WindowsBuildNotesChromeTools.md) 
- Make sure to add exception to the build folder for Windows defender, or it will delete a couple of the build files.
  - Go to Start button > Settings > Update & Security > Windows Security > Virus & threat protection.
  - Under Virus & threat protection settings, select Manage settings, and then under Exclusions, select Add or remove exclusions.
  - Add folder `.\Build-Electron` (which is the default build folder used below, or the build folder you actually use).
- Add to git support for long file names: `git config --system core.longpaths true`
- Installed VS 2019 Community edition and Windows SDKs 10.0.19041.0 and 10.0.20348.0.  Some Electron build will pick the one it needs.
- Installed Python 3.9.11 (Python 3.10 has breaking changes that broke Electron compile) from `https://www.python.org/downloads/` .  Check by `python3 --version`.
- make sure there is a Python 2 installed by `python --version` (should report 2.x.x)
- configured Python:
```
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install pywin32
```
- installed node LTS
- Added environment variables:
```
vs2019_install=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community
WINDOWSSDKDIR=C:\Program Files (x86)\Windows Kits\10
```

- installed: https://chocolatey.org/install
	
- Setup Build tools in build folder (using command prompt, not powershell).  Install using powershell didn't work for me:
```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

### Build Electronite
- first make sure you have downloaded the current version of electronite-tools-3.bat.  There may have been changes from other electronite versions.

#### Build Intel x64
- open command prompt, cd to the build directory, and initialize build configuration:
```
set Path=%cd%\depot_tools;%Path%
.\electronite-tools-3.bat get electronite-v25.3.2-beta
```

- Do build (takes a long time)
```
.\electronite-tools-3.bat build x64; 
.\electronite-tools-3.bat release x64; 
```

- Test the build.
    - Open electron.exe in finder, or run `electron.exe "https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo"`.
    - Open the developer console by typing`Control-Shift-I`.
    - if it didn't open to test page, then in console execute `window.location="https://scripts.sil.org/cms/scripts/page.php?site_id=projects&item_id=graphite_fontdemo"`
    - Ensure all the tests pass by visually inspecting the rendered fonts and comparing against the image samples on the site.
    - The example for Padauk from server will not be correct with the triangles.  So need to:
      Open elements tab, select body of html, do Control-F to search, and search for `padauk_ttf`, and apply attribute `font-feature-settings: "wtri" 1;`.  The triangles should now be rendered correctly.

- The release is at .\Build-Electron\src\out\Release-x64\dist.zip

#### Build Intel x86 (32 bit)
- if Electronite source already checked out, then skip to `Do build` step.

- get the Electronite source code (this can take many hours the first time as the git cache is loaded), checkout the correct Electronite tag and get build sources
```
set Path=%cd%\depot_tools;%Path%
.\electronite-tools-3.bat get electronite-v25.3.2-beta
```

- Do build (takes a long time)
```
.\electronite-tools-3.bat build x86; 
.\electronite-tools-3.bat release x86; 
```

- The release is at .\Build-Electron\src\out\Release-x86\dist.zip

#### Build Intel arm64
- if Electronite source already checked out, then skip to `Do build` step.

-- get the Electronite source code (this can take many hours the first time as the git cache is loaded), checkout the correct Electronite tag and get build sources
```
set Path=%cd%\depot_tools;%Path%
.\electronite-tools-3.bat get electronite-v25.3.2-beta
```

- Do build (takes a long time)
```
.\electronite-tools-3.bat build arm64; 
.\electronite-tools-3.bat release arm64; 
```

- The release is at .\Build-Electron\src\out\Release-arm64\dist.zip

