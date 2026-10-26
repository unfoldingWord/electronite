echo off
set ELECTRONITE_REPO="https://github.com/unfoldingWord/electronite"
set working_dir=%cd%
set GIT_CACHE_PATH=%working_dir%\git_cache
mkdir %GIT_CACHE_PATH%

rem sccache no longer supported in Electron
rem set SCCACHE_BUCKET=electronjs-sccache
rem set SCCACHE_TWO_TIER=true

set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set NINJA_STATUS="[%%r processes, %%f/%%t @ %%o/s : %%es] "
echo "GIT_CACHE_PATH=%GIT_CACHE_PATH%"
echo "SCCACHE_BUCKET=%SCCACHE_BUCKET%"
echo "working_dir=%working_dir%"

echo "%date% - %time%" > start_time.txt

rem TODO: configure environment variables.

rem ------------------------
rem check command to execute
rem ------------------------
if %1.==. goto MissingArgs

rem -------------
rem start command
rem -------------
if "%1" == "get" goto Get
if "%1" == "build" goto Build
if "%1" == "release" goto Release
goto MissingTag

:Get
rem ####################
rem fetch code
rem ####################
if %2.==. goto MissingTag
set checkout_tag=%2

rem make sure depot_tools is clean
echo Preparing depot_tools
FOR /F "tokens=* USEBACKQ" %%F IN (`where gclient.bat`) DO (
set depot_tools_dir=%%~dpF
)
echo depot_tools_dir=%depot_tools_dir%"
cd %depot_tools_dir% && call git reset HEAD --hard && echo depot_tools is ready
cd %working_dir%

rem fetch code
echo Fetching code. This will take a long time and download up to 16GB.
echo Deleting electron-gn folder.
if exist electron-gn rmdir /Q /S electron-gn
echo Deleted electron-gn folder.
mkdir electron-gn
cd electron-gn
call gclient config --name "src/electron" --unmanaged %ELECTRONITE_REPO%
call gclient sync --with_branch_heads --with_tags --nohooks --noprehooks
cd src\electron
echo Checking out %checkout_tag% in %cd%
call git checkout %checkout_tag%
cd ..

rem echo Show Changes
rem call git status
echo Commit all Changes so sync with patches will not fail?
rem this is a hack so that Windows sync will not fail when there are uncommitted changes after git checkout
call git add -A
call git commit -m "commit changes" --author="A U Thor <author@example.com>"
cd..

echo Applying electron patches
call gclient sync --with_branch_heads --with_tags

goto End

:Build
rem ####################
rem build release
rem ####################
set build_x64=false
if "%2" == "" set build_x64=true

echo Building release
cd electron-gn\src
set CHROMIUM_BUILDTOOLS_PATH=%cd%\buildtools

if %build_x64% == false (
    echo Generating %2 configuration...
    call gn gen out/Release-%2 --args="target_cpu=\"%2\" import(\"//electron/build/args/release.gn\")"
    call ninja -C out/Release-%2 electron
) else (
    echo Generating configuration...
    call gn gen out/Release --args="import(\"//electron/build/args/release.gn\")"
    call ninja -C out/Release electron
)

goto End

:Release
rem ####################
rem create distributable
rem ####################
set build_x64=false
if "%2" == "" set build_x64=true

echo Making release
cd electron-gn\src

if %build_x64% == false (
    echo Creating %2 distributable
    electron\script\strip-binaries.py -d out\Release-%2
    call ninja -C out\Release-%2 electron:electron_dist_zip
) else (
    echo Creating distributable
    electron\script\strip-binaries.py -d out\Release
    call ninja -C out\Release electron:electron_dist_zip
)

goto End

rem ####################
rem help text
rem ####################

:MissingArgs
    echo ***********************
    echo *  Electronite Tools  *
    echo ***********************
    echo This is a set of tools for compiling electronite.
    echo The source for electronite is at https://github.com/unfoldingWord-dev/electronite.
    echo Usage: ./electronite-tools.sh ^<command^>
    echo where ^<command^> is one of:
    echo     get ^<ref^>     - fetches all of the code.
    echo                       Where ^<ref^> is a branch or tag.
    echo     build [arch]    - compiles Electronite. The default arch is x64, but you can specify x86.
    echo     release [arch]  - creates the distributable. The default arch is x64, but you can specify x86.
    echo For detailed instructions on building Electron
    echo see https://github.com/electron/electron/blob/master/docs/development/build-instructions-gn.md
    goto End
:MissingTag
    echo Missing the ^<ref^> to checkout. Please specify a tag or branch name.
    goto End
:End

cd %working_dir%

echo "%date% - %time%" > end_time.txt
