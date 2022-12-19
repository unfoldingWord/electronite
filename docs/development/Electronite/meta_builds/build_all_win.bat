set BRANCH=%1
set DEST=%2

rem Example `build_all_win.bat electronite-v22.0.0-initialBuild results\v22.0.0`

echo "Building %BRANCH% to: %DEST%"

if not exist src (
    echo "Getting sources from %BRANCH%"
    .\electronite-tools-3.bat get %BRANCH%
)

set TARGET=x64
set DEST_FILE=%DEST%\%TARGET%\dist.zip
if exist %DEST_FILE% (
    echo "Build %TARGET% already exists: %DEST_FILE%"
) else (
    echo "Doing Build %TARGET%"
    call build_target_win.bat %TARGET% %DEST%
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
    call build_target_win.bat %TARGET% %DEST%
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
    call build_target_win.bat %TARGET% %DEST%
)

if exist %DEST_FILE% (
    echo "Distribution %TARGET% built: %DEST_FILE%"
) else (
    echo "Distribution %TARGET% failed: %DEST_FILE%"
    exit /b 10
)
