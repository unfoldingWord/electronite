echo on

rem Base Build script to do one of: getting sources, building Electronite executable, packaging Electronite as dist.zip
rem
rem Uses Electronite build tools.
rem
rem need to set paths before running this script.
rem     `set Path=%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\third_party\depot_tools;%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\src;%Path%`
rem
rem to troubleshoot build problems, do build logging by doing `set BUILD_EXTRAS=-vvvvv` before running

set FORK=unfoldingWord/electronite
set ELECTRONITE_REPO=https://github.com/unfoldingWord/electronite
rem set Path=%Path%;%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\third_party\depot_tools;%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\src
echo "Path = %Path%"
set working_dir=%cd%
set GIT_CACHE_PATH=%working_dir%\git_cache
mkdir %GIT_CACHE_PATH%
set COMMAND=%1
set TARGET=%2
rem Count in roman numerals
set PASS=%PASS%I

rem sccache no longer supported in Electron
rem set SCCACHE_BUCKET=electronjs-sccache
rem set SCCACHE_TWO_TIER=true

set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set NINJA_STATUS="[%%r processes, %%f/%%t @ %%o/s : %%es] "
echo "GIT_CACHE_PATH=%GIT_CACHE_PATH%"
echo "SCCACHE_BUCKET=%SCCACHE_BUCKET%"
echo "working_dir=%working_dir%"

echo "%date% - %time%" > start_time_%COMMAND%_%TARGET%_%PASS%.txt

if %GOMA%.==. (
  set GOMA=none
  echo "GOMA defaulting to %GOMA%"
) else (
  echo "GOMA is set to %GOMA%"
)

setlocal

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
set BRANCH=%2

rem make sure depot_tools is clean
echo Preparing depot_tools
FOR /F "tokens=* USEBACKQ" %%F IN (`where gclient.bat`) DO (
  set depot_tools_dir=%%~dpF
)
echo depot_tools_dir=%depot_tools_dir%"
cd %depot_tools_dir% && call git reset HEAD --hard && echo depot_tools is ready
cd %working_dir%

rem remove cached electronite repo
if exist .\git_cache\github.com-unfoldingword-electronite rmdir /Q /S .\git_cache\github.com-unfoldingword-electronite
if exist .\git_cache\github.com-unfoldingword-electronite.locked del /f .\git_cache\github.com-unfoldingword-electronite.locked

rem fetch code
echo "Fetching code. This can take hours and download over 20GB."
echo "Deleting src folder"
if exist src rmdir /Q /S src
echo "Deleted src folder"

echo "Checking out %ELECTRONITE_REPO%.git@origin/%BRANCH%"
rem clear old configs
set CONFIG_FILE=%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\configs\evm.x64.json
del %CONFIG_FILE%
del .\.gclient

call e init --root=. -o x64 x64 -i release --goma cache-only --fork %FORK% --use-https -f
rem echo "Config: %CONFIG_FILE%"
rem pause

rem add branch to fork
call sed -i.orig "s|%FORK%.git|%FORK%.git@origin/%BRANCH%|g" %CONFIG_FILE%
call sed -i.orig "s|https://github.com/electron/electron|https://github.com/%FORK%.git@origin/%BRANCH%|g" .\.gclient
rem call type %CONFIG_FILE%
rem pause

rem echo "Config: %CONFIG_FILE%"
echo "Checking out branch and Applying electronite patches"
call  e sync
  
echo "Identify checked out branch"
cd src\electron
call git --version
call git status
call git describe --tags
rem pause
cd ..\..

rem save in case graphite patch fails
echo "%date% - %time%" > end_time_%COMMAND%_%TARGET%_%PASS%.txt

echo "Applying graphite patches"
cd .\src
call git apply --whitespace=warn .\electron\docs\development\Electronite\add_graphite_cpp_std_iterator.patch
cd ..

goto End

:Build
rem ####################
rem build release
rem ####################
if NOT %TARGET%.==. (
    echo "Building for %TARGET%"
) else (
    echo "Building for default x64"
    set TARGET=x64
)

echo "Building..."

set CONFIG_FILE=%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\configs\evm.%TARGET%.json
set RELEASE_TARGET="-%TARGET%"
call e init --root=. -o %TARGET% %TARGET% -i release --goma %GOMA% --fork %FORK% --use-https -f

rem add target architecture to config
call sed -i.orig "s|release.gn\\\x22)\x22|release.gn\\\x22)\x22, \x22target_cpu = \\\x22%TARGET%\\\x22\x22|g" "%CONFIG_FILE%"

rem pause

echo "Building Electronite..."  
call e build electron
  
goto End

:Release
rem ####################
rem create distributable
rem ####################
if NOT %TARGET%.==. (
    echo "Building for %TARGET%"
) else (
    echo "Building for default x64"
    set TARGET=x64
)

echo "Making release"

set CONFIG_FILE=%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\configs\evm.%TARGET%.json
set RELEASE_TARGET="-%TARGET%"
call e init --root=. -o %TARGET% %TARGET% -i release --goma %GOMA% --fork %FORK% --use-https -f
rem add target architecture to config
call sed -i.orig "s|release.gn\\\x22)\x22|release.gn\\\x22)\x22, \x22target_cpu = \\\x22%TARGET%\\\x22\x22|g" "%CONFIG_FILE%"

echo "Creating Electronite Distributable..."
call e build electron:dist
  
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

echo "%date% - %time%" > end_time_%COMMAND%_%TARGET%_%PASS%.txt
