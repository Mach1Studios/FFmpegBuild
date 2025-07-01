#!/bin/bash

# FFmpeg Build Configuration Examples
# This script shows various configuration examples for different platforms and use cases

echo "=== FFmpeg Build Configuration Examples ==="
echo
echo "Choose a configuration by running one of the commands below:"
echo

echo "📱 BASIC CONFIGURATIONS:"
echo
echo "# Basic build (auto-detects platform)"
echo "cmake .. -DCMAKE_BUILD_TYPE=Release"
echo

echo "🍎 MACOS CONFIGURATIONS:"
echo
echo "# Standard macOS build"
echo "cmake .. -DFFMPEG_MAC_UNIVERSAL_BINARY=OFF -DCMAKE_BUILD_TYPE=Release"
echo
echo "# macOS Universal Binary (x86_64 + arm64)"
echo "cmake .. -DFFMPEG_MAC_UNIVERSAL_BINARY=ON -DCMAKE_BUILD_TYPE=Release"
echo

echo "🐧 LINUX CONFIGURATIONS:"
echo
echo "# Linux shared libraries"
echo "cmake .. -DFFMPEG_LINUX_BUILD=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release"
echo
echo "# Linux static libraries"
echo "cmake .. -DFFMPEG_LINUX_BUILD=ON -DFFMPEG_LINUX_STATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release"
echo
echo "# Linux with combined static library"
echo "cmake .. -DFFMPEG_LINUX_BUILD=ON -DFFMPEG_LINUX_STATIC_BUILD=ON -DFFMPEG_LINUX_CREATE_COMBINED_STATIC=ON -DCMAKE_BUILD_TYPE=Release"
echo

echo "🪟 WINDOWS CONFIGURATIONS:"
echo
echo "# Windows with MSYS2/MinGW (recommended)"
echo "cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON -DCMAKE_BUILD_TYPE=Release"
echo
echo "# Windows with MSVC (advanced, requires manual setup)"
echo "cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=OFF -DCMAKE_BUILD_TYPE=Release"
echo
echo "# Cross-compile for Windows (from Linux/macOS)"
echo "cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_CROSS_COMPILE=ON -DCMAKE_BUILD_TYPE=Release"
echo

echo "🔧 ADVANCED CONFIGURATIONS:"
echo
echo "# Custom FFmpeg version"
echo "cmake .. -DFFMPEG_VERSION=6.0 -DCMAKE_BUILD_TYPE=Release"
echo
echo "# Debug build with verbose output"
echo "cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_VERBOSE_MAKEFILE=ON"
echo
echo "# Install to custom prefix"
echo "cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/ffmpeg -DCMAKE_BUILD_TYPE=Release"
echo

echo "🚀 BUILD AND INSTALL:"
echo
echo "# After configuring, build with:"
echo "cmake --build . --config Release"
echo
echo "# Install with:"
echo "cmake --install . --config Release"
echo
echo "# Or build specific target:"
echo "cmake --build . --target ffmpeg_build --config Release"
echo

echo "🧪 TESTING:"
echo
echo "# Test current platform only"
echo "./test-build.sh"
echo
echo "# Test specific platform"
echo "./test-build.sh --platform linux"
echo
echo "# Test all platform configurations"
echo "./test-build.sh --all-platforms"
echo

echo "💡 TIPS:"
echo
echo "- On Windows, run setup-windows.bat to check your environment"
echo "- On Windows, make sure MSYS2 is in your PATH"
echo "- On macOS, install yasm for optimized builds: brew install yasm"
echo "- On Linux, install nasm for assembly optimizations: sudo apt install nasm"
echo "- For codec support on Linux, install development libraries (libx264-dev, libx265-dev, etc.)"
echo
echo "📋 SETUP SCRIPTS:"
echo
echo "# Windows environment check and setup"
echo "setup-windows.bat"
echo
echo "# Test configurations"
echo "./test-build.sh" 