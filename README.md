# FFmpeg CMake Build System

A comprehensive CMake-based build system for FFmpeg that supports multiple platforms including macOS, Windows, and Linux. This build system automatically downloads FFmpeg source code and builds it using platform-specific optimizations.

## Supported Platforms

- **macOS**: Native builds with universal binary support (x86_64 + arm64)
- **Windows**: MSYS2/MinGW and MSVC toolchain support
- **Linux**: Native builds with GCC/Clang, static/shared library options
- **iOS/Android**: Cross-compilation support (inherited from original)

## Quick Start

### Prerequisites

#### macOS
- Xcode Command Line Tools
- For universal binaries: `yasm` (install via Homebrew: `brew install yasm`)

#### Windows
- **Option 1 (Recommended): MSYS2**
  - Install [MSYS2](https://www.msys2.org/)
  - Install development tools: `pacman -S base-devel mingw-w64-x86_64-toolchain`
- **Option 2: Visual Studio**
  - Visual Studio with C++ build tools
  - Additional manual configuration required

#### Linux
- GCC or Clang compiler
- Make and standard build tools
- Optional but recommended: `nasm` for assembly optimizations
- Optional: codec libraries (libx264, libx265, libvpx, etc.)

### Basic Usage

```bash
# Clone the repository
git clone <repository-url>
cd FFmpegBuild

# Configure and build
mkdir build
cd build
cmake ..
cmake --build .

# Install (optional)
cmake --install .
```

## Platform-Specific Configuration

### macOS

```bash
# Standard build
cmake ..

# Universal binary (x86_64 + arm64)
cmake -DFFMPEG_MAC_UNIVERSAL_BINARY=ON ..

# Disable universal binary
cmake -DFFMPEG_MAC_UNIVERSAL_BINARY=OFF ..
```

### Windows

```bash
# Using MSYS2 (recommended)
cmake -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON ..

# Using MSVC (advanced)
cmake -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=OFF ..

# Cross-compilation for Windows (from Linux/macOS)
cmake -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_CROSS_COMPILE=ON ..
```

### Linux

```bash
# Shared libraries (default)
cmake -DFFMPEG_LINUX_BUILD=ON ..

# Static libraries
cmake -DFFMPEG_LINUX_BUILD=ON -DFFMPEG_LINUX_STATIC_BUILD=ON ..

# Or use the global BUILD_SHARED_LIBS option
cmake -DFFMPEG_LINUX_BUILD=ON -DBUILD_SHARED_LIBS=OFF ..
```

## Configuration Options

### Global Options

- `BUILD_SHARED_LIBS`: Build shared libraries instead of static (default: OFF)
- `FFMPEG_VERSION`: FFmpeg version to download and build (default: 5.1.6)
- `FFMPEG_ENABLE_CROSS_COMPILATION`: Enable cross-compilation support

### Platform-Specific Options

#### macOS
- `FFMPEG_MAC_UNIVERSAL_BINARY`: Build universal binary for both x86_64 and arm64

#### Windows
- `FFMPEG_WINDOWS_BUILD`: Enable Windows build
- `FFMPEG_WINDOWS_USE_MSYS2`: Use MSYS2/MinGW toolchain (recommended)
- `FFMPEG_WINDOWS_CROSS_COMPILE`: Cross-compile for Windows from other platforms

#### Linux
- `FFMPEG_LINUX_BUILD`: Enable Linux build
- `FFMPEG_LINUX_STATIC_BUILD`: Build static libraries
- `FFMPEG_LINUX_CREATE_COMBINED_STATIC`: Create a combined static library

## Advanced Usage

### Custom FFmpeg Version

```bash
cmake -DFFMPEG_VERSION=6.0 ..
```

### Custom Source Directory

```bash
cmake -DFFMPEG_SOURCE_DIR=/path/to/ffmpeg-source ..
```

### Cross-Compilation

The build system supports cross-compilation scenarios:

1. **Windows from Linux**: Install MinGW-w64 cross-compiler
2. **Windows from macOS**: Use Homebrew to install MinGW-w64
3. **Linux from macOS**: Use appropriate cross-compilation toolchain

## Output Structure

After building, the libraries and headers will be organized as follows:

```
build/
├── ffmpeg/
│   ├── include/           # Headers
│   ├── libavutil.*        # Core utilities
│   ├── libavcodec.*       # Codecs
│   ├── libavformat.*      # Container formats
│   ├── libswscale.*       # Video scaling
│   └── libswresample.*    # Audio resampling
```

Platform-specific builds create subdirectories:
- `build/ffmpeg/linux/` - Linux build outputs
- `build/ffmpeg/windows/` - Windows build outputs
- `build/ffmpeg/x86_64/` and `build/ffmpeg/arm64/` - macOS universal binary components

## Integration with Other Projects

### Using find_package

After installation, you can use FFmpeg in other CMake projects:

```cmake
find_package(FFmpeg REQUIRED)
target_link_libraries(your_target ffmpeg::ffmpeg)
```

### Manual Integration

```cmake
# Add this project as a subdirectory
add_subdirectory(path/to/FFmpegBuild)

# Link against the ffmpeg target
target_link_libraries(your_target ffmpeg::ffmpeg)
```

## Testing

The build system includes a comprehensive test script that can validate configurations:

### Test Script Usage

```bash
# Test current platform only
./test-build.sh

# Test specific platform
./test-build.sh --platform linux
./test-build.sh --platform windows
./test-build.sh --platform macos

# Test all platform configurations (may fail on unsupported platforms)
./test-build.sh --all-platforms

# Show help
./test-build.sh --help
```

### What the Test Script Does

- **Local Platform Testing**: By default, tests only the current platform's configurations
- **Cross-Platform Configuration Testing**: With `--all-platforms`, attempts to test all platform configurations
- **Configuration Validation**: Checks that CMake configuration succeeds without building
- **Dependency Detection**: Verifies required tools and paths are found
- **Feature Testing**: Tests platform-specific features and options

**Note**: The test script performs configuration testing only - it doesn't actually build FFmpeg (which would take much longer). Some cross-platform tests may fail if the required toolchains aren't installed.

### Configuration Examples

Run `./configure-examples.sh` to see various configuration examples for different platforms and use cases.

## Troubleshooting

### Windows Issues

1. **'bash.exe' is not recognized as an internal or external command**:
   ```
   'C:\Windows\System32\bash.exe' is not recognized as an internal or external command
   ```
   This means the build system is trying to use WSL bash instead of MSYS2 bash. Solutions:
   - Install MSYS2 from https://www.msys2.org/
   - Install build tools: `pacman -S base-devel mingw-w64-x86_64-toolchain`
   - Set environment variable: `MSYS2_ROOT=C:\msys64` (or your MSYS2 path)
   - Alternatively, disable MSYS2: `cmake .. -DFFMPEG_WINDOWS_USE_MSYS2=OFF`

2. **MSYS2 not found**: Ensure MSYS2 is installed and paths are correct
3. **MinGW compiler not found**: Install the toolchain: `pacman -S mingw-w64-x86_64-toolchain`
4. **Path issues**: Make sure MSYS2 paths are correctly detected
5. **avconfig.h not found**: This file is generated during build - the error should be resolved with the updated build scripts

#### Windows Build Environment Setup

**Quick Setup (Recommended)**:
```bash
# Run the automated setup script
setup-windows.bat
```

For manual setup or troubleshooting:

1. **Install MSYS2**:
   ```bash
   # Download from https://www.msys2.org/
   # Install to C:\msys64 (recommended)
   ```

2. **Install build tools**:
   ```bash
   # Open MSYS2 terminal
   pacman -S base-devel mingw-w64-x86_64-toolchain
   ```

3. **Configure your project**:
   ```bash
   # From regular Windows Command Prompt or PowerShell
   cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON
   ```

4. **If MSYS2 is in a non-standard location**:
   ```bash
   # Set environment variable
   set MSYS2_ROOT=D:\msys64
   # or
   cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON -DMSYS2_ROOT=D:\msys64
   ```

### Linux Issues

1. **Missing dependencies**: Install development packages for your distribution
2. **NASM not found**: Install nasm for optimized builds: `sudo apt install nasm` (Ubuntu) or `sudo yum install nasm` (RHEL/CentOS)
3. **Codec libraries**: Optional codecs require their development libraries

### macOS Issues

1. **Xcode Command Line Tools**: Install with `xcode-select --install`
2. **Universal binary fails**: Ensure both architectures are supported and yasm is available

### General Issues

1. **Download failures**: Check internet connection and firewall settings
2. **Build failures**: Check that all required tools are installed and accessible
3. **Permission errors**: Ensure write permissions in build directory

## Codec Support

The build system enables different codec sets based on platform and available libraries:

### Linux
- Automatically detects and enables available codec libraries
- Supports GPL codecs (x264, x265, etc.) if libraries are installed
- Hardware acceleration support (VAAPI, VDPAU, NVENC)

### Windows
- Basic codec set enabled by default
- Extended codec support requires additional libraries in MSYS2

### macOS
- Standard codec support
- VideoToolbox hardware acceleration support

## Contributing

When contributing to this build system:

1. Test changes on all supported platforms when possible
2. Update documentation for new options or platforms
3. Follow the existing CMake coding style
4. Add appropriate error handling and user feedback

## License

This build system is provided as-is. FFmpeg itself is licensed under the LGPL/GPL depending on the configuration options used. Please refer to FFmpeg's licensing documentation for details on the resulting binary licensing.

## Version History

- **Current**: Multi-platform support (Windows, Linux, macOS)
- **Previous**: macOS-focused build with iOS/Android support
