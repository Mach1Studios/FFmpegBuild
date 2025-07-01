@echo off
REM FFmpeg Windows Build Environment Setup Script
REM This script helps diagnose and set up the Windows build environment

echo ================================================
echo FFmpeg Windows Build Environment Setup
echo ================================================
echo.

REM Check for MSYS2 installation
echo Checking for MSYS2 installation...
set MSYS2_FOUND=0

if exist "C:\msys64\usr\bin\bash.exe" (
    echo Found MSYS2 at C:\msys64
    set MSYS2_ROOT=C:\msys64
    set MSYS2_FOUND=1
) else if exist "C:\msys2\usr\bin\bash.exe" (
    echo Found MSYS2 at C:\msys2
    set MSYS2_ROOT=C:\msys2
    set MSYS2_FOUND=1
) else if exist "D:\msys64\usr\bin\bash.exe" (
    echo Found MSYS2 at D:\msys64
    set MSYS2_ROOT=D:\msys64
    set MSYS2_FOUND=1
) else if exist "D:\msys2\usr\bin\bash.exe" (
    echo Found MSYS2 at D:\msys2
    set MSYS2_ROOT=D:\msys2
    set MSYS2_FOUND=1
) else (
    echo MSYS2 not found in standard locations
    set MSYS2_FOUND=0
)

if %MSYS2_FOUND%==0 (
    echo.
    echo MSYS2 NOT FOUND
    echo.
    echo Please install MSYS2:
    echo 1. Download from https://www.msys2.org/
    echo 2. Install to C:\msys64 ^(recommended^)
    echo 3. Run this script again
    echo.
    pause
    exit /b 1
)

REM Check for build tools
echo.
echo Checking for build tools...
if exist "%MSYS2_ROOT%\usr\bin\make.exe" (
    echo make found
) else (
    echo make not found
    echo Please install build tools:
    echo Open MSYS2 terminal and run: pacman -S base-devel
)

if exist "%MSYS2_ROOT%\mingw64\bin\gcc.exe" (
    echo MinGW GCC found
) else (
    echo MinGW GCC not found
    echo Please install MinGW toolchain:
    echo Open MSYS2 terminal and run: pacman -S mingw-w64-x86_64-toolchain
)

REM Check for WSL bash that might interfere
echo.
echo Checking for potential conflicts...
if exist "C:\Windows\System32\bash.exe" (
    echo WARNING: WSL bash found at C:\Windows\System32\bash.exe
    echo This might interfere with MSYS2 bash
    echo The build system has been updated to avoid this conflict
) else (
    echo No WSL bash conflicts detected
)

REM Set environment variables
echo.
echo Setting up environment...
set MSYS2_ROOT=%MSYS2_ROOT%
echo MSYS2_ROOT=%MSYS2_ROOT%

REM Provide configuration commands
echo.
echo ================================================
echo Configuration Commands
echo ================================================
echo.
echo To configure FFmpeg build for Windows:
echo.
echo   mkdir build
echo   cd build
echo   cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON
echo.
echo To build:
echo   cmake --build . --config Release
echo.
echo If MSYS2 is in a different location, use:
echo   cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON -DMSYS2_ROOT=%MSYS2_ROOT%
echo.

if %MSYS2_FOUND%==1 (
    echo Environment setup complete!
    echo Your MSYS2 installation: %MSYS2_ROOT%
) else (
    echo Environment setup incomplete - please install MSYS2
)

echo.
echo Press any key to continue...
pause >nul 