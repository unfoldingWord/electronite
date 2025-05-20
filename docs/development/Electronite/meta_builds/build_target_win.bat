set TARGET=%1
set DEST=%2

rem Build script to do build build and release for %TARGET% if not present at %DEST%
rem
rem Uses Chromium build tools.
rem
rem need to set paths before running this script. cd to the build directory and do:
rem     `set Path=%cd%\depot_tools;%Path%`
rem
rem to troubleshoot build problems, do build logging by doing `set BUILD_EXTRAS=-vvvvv` before running
rem
rem Example `build_target_win.bat x64 results`

echo "Building %TARGET% to: %DEST%"


set BUILD_TARGET=.\src\out\Release-%TARGET%\electron.exe
if exist %BUILD_TARGET% (
    echo "Build Target already exists: %BUILD_TARGET%"
) else (
    echo "Doing Build %TARGET%"
    call .\electronite-tools-3.bat build %TARGET%
    echo "Finish Build %TARGET%"
)

if exist %BUILD_TARGET% (
    echo "Target built: %BUILD_TARGET%"
) else (
    echo "Target failed: %BUILD_TARGET%"
    exit /b 10
)

set RELEASE_TARGET=.\src\out\Release-%TARGET%\dist.zip
if exist %RELEASE_TARGET% (
    echo "Release Target already exists: %RELEASE_TARGET%"
) else (
    echo "Doing Release %RELEASE_TARGET%"
    call .\electronite-tools-3.bat release %TARGET%
    echo "Finished Release %RELEASE_TARGET%"
)

if exist %RELEASE_TARGET% (
    echo "Target released: %RELEASE_TARGET%"
) else (
    echo "Target failed: %RELEASE_TARGET%"
    exit /b 10
)

set DEST_FOLDER=%DEST%\%TARGET%
if not exist %DEST_FOLDER% (
    echo "Creating Destination folder: %DEST_FOLDER%"
    md "%DEST_FOLDER%"
)

if not exist %DEST_FOLDER% (
    echo "Error Creating Destination folder: %DEST_FOLDER%"
    exit /b 10
)

set DEST_FILE=%DEST_FOLDER%\dist.zip
echo "Copy from %RELEASE_TARGET% to %DEST_FILE%"
copy %RELEASE_TARGET% %DEST_FILE%
if not exist %DEST_FILE% (
    echo "Error moving dist.zip file to: %DEST_FILE%"
    exit /b 10
)

set TARGET_FOLDER=.\src\out\Release-%TARGET%
echo "Remove %TARGET_FOLDER% to free up space for later builds'
rmdir /s /q %TARGET_FOLDER%
if exist %TARGET_FOLDER% (
    echo "Error removing %TARGET_FOLDER%"
    exit /b 10
)

echo "Done copying build to %TARGET_FOLDER%"
