set BRANCH=%1
set DEST=%2

rem Meta Build script to get sources, and then build for x64, x86, and arm64 by calling build_target_win.bat
rem     for each architecture.  The dist.zip files are stored at %DEST%
rem
rem Uses Chromium build tools.
rem
rem need to set paths before running this script. cd to the build directory and do:
rem     `set Path=%cd%\depot_tools;%Path%`
rem
rem to troubleshoot build problems, do build logging by doing `set BUILD_EXTRAS=-vvvvv` before running
rem
rem Example `build_all_win.bat electronite-v38.7.1-beta results\win\v38.7.1`

echo "Building %BRANCH% to: %DEST%"

if not exist src (
    echo "Getting sources from %BRANCH%"
    call electronite-tools-3.bat get %BRANCH%
)

set TARGET_=x64
set DEST_FILE=%DEST%\%TARGET_%\dist.zip
if exist %DEST_FILE% (
    echo "Build %TARGET_% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET_%"
    call build_target_win.bat %TARGET_% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET_% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET_% failed: %DEST_FILE%"
    exit /b 10
)

set TARGET_=x86
set DEST_FILE=%DEST%\%TARGET_%\dist.zip

if exist %DEST_FILE% (
    echo "Build %TARGET_% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET_%"
    call build_target_win.bat %TARGET_% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET_% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET_% failed: %DEST_FILE%"
    exit /b 10
)

set TARGET_=arm64
set DEST_FILE=%DEST%\%TARGET_%\dist.zip
if exist %DEST_FILE% (
    echo "Build %TARGET_% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET_%"
    call build_target_win.bat %TARGET_% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET_% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET_% failed: %DEST_FILE%"
    exit /b 10
)

echo "All builds completed to %DEST%"
