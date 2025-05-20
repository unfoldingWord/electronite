set BRANCH=%1
set DEST=%2

rem Meta Build script to get sources, and then build for x64, x86, and arm64 by calling build_target_win.bat
rem     for each architecture.  The dist.zip files are stored at %DEST%
rem
rem Uses Electronite build tools.
rem
rem need to set paths before running this script.
rem     `set Path=%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\third_party\depot_tools;%HOMEDRIVE%%HOMEPATH%\.electron_build_tools\src;%Path%`
rem
rem to enable goma, do `set GOMA=cache-only` before running script
rem
rem to troubleshoot build problems, do build logging by doing `set BUILD_EXTRAS=-vvvvv` before running
rem
rem Example `build_all_goma_win.bat electronite-v25.3.2-beta results\win\v25.3.2`

echo "Building %BRANCH% to: %DEST%"

if not exist src (
    echo "Getting sources from %BRANCH%"
    call electronite-tools-goma-3.bat get %BRANCH%
)

set TARGET=x64
set DEST_FILE=%DEST%\%TARGET%\dist.zip
if exist %DEST_FILE% (
    echo "Build %TARGET% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET%"
    call build_target_goma_win.bat %TARGET% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET% failed: %DEST_FILE%"
    exit /b 10
)

set TARGET=x86
set DEST_FILE=%DEST%\%TARGET%\dist.zip

if exist %DEST_FILE% (
    echo "Build %TARGET% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET%"
    call build_target_goma_win.bat %TARGET% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET% failed: %DEST_FILE%"
    exit /b 10
)

set TARGET=arm64
set DEST_FILE=%DEST%\%TARGET%\dist.zip
if exist %DEST_FILE% (
    echo "Build %TARGET% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET%"
    call build_target_goma_win.bat %TARGET% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET% failed: %DEST_FILE%"
    exit /b 10
)

echo "All builds completed to %DEST%"
