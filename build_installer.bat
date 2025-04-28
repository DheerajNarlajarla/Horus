@echo off
echo === Horus Windows Installer Build Script ===
echo This script will build Horus and create a Windows installer
echo.

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo PowerShell is not available. Please install PowerShell to continue.
    exit /b 1
)

REM Run the PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File build_windows_installer.ps1

if %ERRORLEVEL% neq 0 (
    echo Failed to build installer. See above for errors.
    exit /b 1
)

echo.
echo Build completed successfully!
pause
