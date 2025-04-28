@echo off
echo === Horus Run Script ===
echo This script will run the Horus application from the build directory
echo.

REM Check if the build directory exists
if not exist "VSCode-win32-x64\Horus.exe" (
    echo Horus build not found. Please build Horus first using build.sh or build_installer.bat
    exit /b 1
)

echo Starting Horus...
start "" "VSCode-win32-x64\Horus.exe"

echo.
echo Horus has been launched!
