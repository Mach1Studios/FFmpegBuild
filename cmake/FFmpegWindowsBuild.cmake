#[[

Windows-specific FFmpeg build configuration.

This file configures FFmpeg builds for Windows, supporting both:
1. MSYS2/MinGW toolchain (recommended)
2. MSVC toolchain (with additional setup required)
3. Cross-compilation from Linux/macOS

Requirements:
- For MSYS2: MSYS2 installation with MinGW-w64 toolchain
- For MSVC: Visual Studio with C++ tools
- For cross-compilation: MinGW-w64 cross-compiler

]]

cmake_minimum_required (VERSION 3.22 FATAL_ERROR)

include_guard (GLOBAL)

message (STATUS "Configuring FFmpeg Windows build...")

# Detect Windows build environment
if (FFMPEG_WINDOWS_USE_MSYS2)
    message (STATUS "Using MSYS2/MinGW toolchain for Windows build")
    
    # Find MSYS2 installation - be more flexible about locations
    find_path (MSYS2_ROOT_PATH
               NAMES usr/bin/bash.exe
               PATHS "C:/msys64" "C:/msys2" "D:/msys64" "D:/msys2" 
                     "$ENV{MSYS2_ROOT}" "$ENV{MSYSTEM_PREFIX}/.."
               DOC "Path to MSYS2 installation root")
    
    if (NOT MSYS2_ROOT_PATH)
        message (WARNING "MSYS2 installation not found. Please install MSYS2 or set MSYS2_ROOT environment variable.")
        message (WARNING "Falling back to standard Windows build (may require additional setup).")
        set (FFMPEG_WINDOWS_USE_MSYS2 OFF)
    else()
        message (STATUS "Found MSYS2 at: ${MSYS2_ROOT_PATH}")
        
        # Find required tools in MSYS2 - avoid WSL bash in System32
        find_program (MSYS2_BASH
                      NAMES bash.exe
                      PATHS "${MSYS2_ROOT_PATH}/usr/bin"
                      NO_DEFAULT_PATH
                      DOC "MSYS2 bash executable"
                      REQUIRED)
        
        find_program (MSYS2_CC
                      NAMES gcc.exe x86_64-w64-mingw32-gcc.exe
                      PATHS "${MSYS2_ROOT_PATH}/mingw64/bin" "${MSYS2_ROOT_PATH}/usr/bin"
                      NO_DEFAULT_PATH
                      DOC "MinGW GCC compiler")
        
        find_program (MSYS2_CXX
                      NAMES g++.exe x86_64-w64-mingw32-g++.exe
                      PATHS "${MSYS2_ROOT_PATH}/mingw64/bin" "${MSYS2_ROOT_PATH}/usr/bin"
                      NO_DEFAULT_PATH
                      DOC "MinGW G++ compiler")
        
        if (NOT MSYS2_CC OR NOT MSYS2_CXX)
            message (WARNING "MinGW compilers not found. Install with: pacman -S mingw-w64-x86_64-toolchain")
            message (WARNING "Falling back to standard Windows build.")
            set (FFMPEG_WINDOWS_USE_MSYS2 OFF)
        else()
            message (STATUS "Found MinGW GCC: ${MSYS2_CC}")
            message (STATUS "Found MinGW G++: ${MSYS2_CXX}")
            
            set (WINDOWS_CONFIGURE_EXTRA_ARGS
                 "--toolchain=gcc"
                 "--enable-cross-compile"
                 "--target-os=win32"
                 "--arch=x86_64"
                 "--cc=${MSYS2_CC}"
                 "--cxx=${MSYS2_CXX}")
        endif()
    endif()
endif()

if (NOT FFMPEG_WINDOWS_USE_MSYS2)
    if (MSVC)
        message (STATUS "Using MSVC toolchain for Windows build")
        
        # MSVC requires additional setup and is more complex
        # FFmpeg's configure script doesn't directly support MSVC well
        message (WARNING "MSVC builds require manual configuration. Consider using MSYS2 instead.")
        
        set (WINDOWS_CONFIGURE_EXTRA_ARGS
             "--toolchain=msvc"
             "--enable-cross-compile"
             "--target-os=win32"
             "--arch=x86_64")
             
    else()
        # Assume MinGW or cross-compilation
        message (STATUS "Using default Windows build configuration")
        
        set (WINDOWS_CONFIGURE_EXTRA_ARGS
             "--enable-cross-compile"
             "--target-os=win32"
             "--arch=x86_64")
    endif()
endif()

# Windows-specific configure options
list (APPEND WINDOWS_CONFIGURE_EXTRA_ARGS
      "--disable-w32threads"  # Use pthreads instead
      "--enable-pthreads"
      "--disable-cuda-nvcc"   # Disable NVIDIA CUDA unless specifically needed
      "--disable-libnpp")

# Configure build
if (PROJECT_IS_TOP_LEVEL)
    set (all_flag ALL)
else ()
    unset (all_flag)
endif ()

set (windows_output_dir "${ffmpeg_output_dir}/windows")

message (DEBUG "Windows output directory: ${windows_output_dir}")

# Configure the build based on available tools
if (FFMPEG_WINDOWS_USE_MSYS2 AND MSYS2_BASH)
    message (STATUS "Configuring MSYS2-based Windows build")
    
    # Convert paths to MSYS2 format
    execute_process (
        COMMAND "${MSYS2_BASH}" -c "cygpath -u '${FFMPEG_SOURCE_DIR}'"
        OUTPUT_VARIABLE MSYS2_SOURCE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
    
    execute_process (
        COMMAND "${MSYS2_BASH}" -c "cygpath -u '${windows_output_dir}'"
        OUTPUT_VARIABLE MSYS2_OUTPUT_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
    
    message (STATUS "MSYS2 source path: ${MSYS2_SOURCE_DIR}")
    message (STATUS "MSYS2 output path: ${MSYS2_OUTPUT_DIR}")
    
    # Build the configure arguments string
    string (REPLACE ";" " " WINDOWS_CONFIGURE_ARGS_STR "${WINDOWS_CONFIGURE_EXTRA_ARGS}")
    
    # Create a more robust wrapper script for the build
    set (WINDOWS_BUILD_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg_windows_build.sh")
    
    file (WRITE "${WINDOWS_BUILD_SCRIPT}"
          "#!/bin/bash\n"
          "set -e\n"
          "echo \"=== FFmpeg Windows Build Script ===\"\n"
          "echo \"Source directory: ${MSYS2_SOURCE_DIR}\"\n"
          "echo \"Output directory: ${MSYS2_OUTPUT_DIR}\"\n"
          "echo \"Working directory: $(pwd)\"\n"
          "\n"
          "# Verify we can access the source directory\n"
          "if [ ! -d '${MSYS2_SOURCE_DIR}' ]; then\n"
          "  echo \"ERROR: Source directory not found: ${MSYS2_SOURCE_DIR}\"\n"
          "  exit 1\n"
          "fi\n"
          "\n"
          "# Change to source directory\n"
          "echo \"Changing to source directory...\"\n"
          "cd '${MSYS2_SOURCE_DIR}'\n"
          "echo \"Current directory: $(pwd)\"\n"
          "\n"
          "# Verify configure script exists\n"
          "if [ ! -f './configure' ]; then\n"
          "  echo \"ERROR: configure script not found in $(pwd)\"\n"
          "  ls -la | head -10\n"
          "  exit 1\n"
          "fi\n"
          "\n"
          "# Clean previous build\n"
          "echo \"Cleaning previous build...\"\n"
          "make distclean || echo \"No previous build to clean\"\n"
          "\n"
          "# Create output directory\n"
          "mkdir -p '${MSYS2_OUTPUT_DIR}'\n"
          "\n"
          "# Configure FFmpeg\n"
          "echo \"Configuring FFmpeg...\"\n"
          "./configure \\\n"
          "  --prefix='${MSYS2_OUTPUT_DIR}' \\\n"
          "  --libdir='${MSYS2_OUTPUT_DIR}' \\\n"
          "  --shlibdir='${MSYS2_OUTPUT_DIR}' \\\n"
          "  --incdir='${MSYS2_OUTPUT_DIR}/include' \\\n"
          "  --disable-doc \\\n"
          "  --disable-asm \\\n"
          "  --disable-lzma \\\n"
          "  --disable-bzlib \\\n"
          "  --disable-zlib \\\n"
          "  ${WINDOWS_CONFIGURE_ARGS_STR}\n"
          "\n"
          "echo \"Starting FFmpeg build...\"\n"
          "make -j${NUM_PROCESSORS}\n"
          "\n"
          "echo \"Installing FFmpeg...\"\n"
          "make install\n"
          "\n"
          "echo \"FFmpeg build completed successfully\"\n")
    
    # Create the build target using MSYS2 - simplified approach
    add_custom_target (
        ffmpeg_build_windows
        ${all_flag}
        COMMAND "${MSYS2_BASH}" "${WINDOWS_BUILD_SCRIPT}"
        WORKING_DIRECTORY "${FFMPEG_SOURCE_DIR}"
        COMMENT "Building FFmpeg for Windows using MSYS2..."
        VERBATIM 
        USES_TERMINAL)

else()
    message (STATUS "Configuring standard Windows build (no MSYS2)")
    message (WARNING "Standard Windows build may require additional manual configuration")
    
    # Try to use the standard build functions
    # This may not work well on Windows without MSYS2, but provides a fallback
    preconfigure_ffmpeg_build (
        SOURCE_DIR "${FFMPEG_SOURCE_DIR}" 
        OUTPUT_DIR "${windows_output_dir}"
        EXTRA_ARGS ${WINDOWS_CONFIGURE_EXTRA_ARGS})

    create_ffmpeg_build_target (
        SOURCE_DIR "${FFMPEG_SOURCE_DIR}" 
        OUTPUT_DIR "${windows_output_dir}"
        BUILD_TARGET ffmpeg_build_windows
        ${all_flag})
endif()

# Note: avconfig.h will be copied after the build completes
# since it's generated by the configure script
file (MAKE_DIRECTORY "${ffmpeg_output_dir}/include/libavutil")

add_dependencies (ffmpeg ffmpeg_build_windows)

# Copy avconfig.h after the build completes (since it's generated by configure)
add_custom_command(
    TARGET ffmpeg_build_windows POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FFMPEG_SOURCE_DIR}/libavutil/avconfig.h"
        "${ffmpeg_output_dir}/include/libavutil/avconfig.h"
    COMMENT "Copying generated avconfig.h for Windows build"
    VERBATIM)

message (STATUS "Windows FFmpeg build configured successfully") 