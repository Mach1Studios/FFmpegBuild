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
    
    # Find MSYS2 installation
    find_path (MSYS2_ROOT_PATH
               NAMES usr/bin/bash.exe
               PATHS "C:/msys64" "C:/msys2"
               DOC "Path to MSYS2 installation root"
               REQUIRED)
    
    # Find required tools in MSYS2
    find_program (MSYS2_BASH
                  NAMES bash.exe
                  PATHS "${MSYS2_ROOT_PATH}/usr/bin"
                  DOC "MSYS2 bash executable"
                  REQUIRED)
    
    find_program (MSYS2_CC
                  NAMES gcc.exe x86_64-w64-mingw32-gcc.exe
                  PATHS "${MSYS2_ROOT_PATH}/mingw64/bin" "${MSYS2_ROOT_PATH}/usr/bin"
                  DOC "MinGW GCC compiler"
                  REQUIRED)
    
    find_program (MSYS2_CXX
                  NAMES g++.exe x86_64-w64-mingw32-g++.exe
                  PATHS "${MSYS2_ROOT_PATH}/mingw64/bin" "${MSYS2_ROOT_PATH}/usr/bin"
                  DOC "MinGW G++ compiler"
                  REQUIRED)
    
    set (WINDOWS_CONFIGURE_EXTRA_ARGS
         "--toolchain=msvc"
         "--enable-cross-compile"
         "--target-os=win32"
         "--arch=x86_64"
         "--cc=${MSYS2_CC}"
         "--cxx=${MSYS2_CXX}")
         
elseif (MSVC)
    message (STATUS "Using MSVC toolchain for Windows build")
    
    # MSVC requires additional setup and is more complex
    # FFmpeg's configure script doesn't directly support MSVC
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

# For Windows, we might need to run configure through MSYS2 bash
if (FFMPEG_WINDOWS_USE_MSYS2 AND MSYS2_BASH)
    # Convert paths to MSYS2 format
    execute_process (
        COMMAND "${MSYS2_BASH}" -c "cygpath -u '${FFMPEG_SOURCE_DIR}'"
        OUTPUT_VARIABLE MSYS2_SOURCE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    
    execute_process (
        COMMAND "${MSYS2_BASH}" -c "cygpath -u '${windows_output_dir}'"
        OUTPUT_VARIABLE MSYS2_OUTPUT_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    
    # Create a wrapper script for the build
    set (WINDOWS_BUILD_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg_windows_build.sh")
    
    file (WRITE "${WINDOWS_BUILD_SCRIPT}"
          "#!/bin/bash\n"
          "set -e\n"
          "cd '${MSYS2_SOURCE_DIR}'\n"
          "make distclean || true\n"
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
          "  ${CMAKE_GENERATOR} ${WINDOWS_CONFIGURE_EXTRA_ARGS}\n"
          "make -j${NUM_PROCESSORS}\n"
          "make install\n")
    
    # Make script executable (if on Unix-like system)
    if (NOT WIN32)
        execute_process (COMMAND chmod +x "${WINDOWS_BUILD_SCRIPT}")
    endif()
    
    # Create the build target
    add_custom_target (
        ffmpeg_build_windows
        ${all_flag}
        COMMAND "${MSYS2_BASH}" "${WINDOWS_BUILD_SCRIPT}"
        WORKING_DIRECTORY "${FFMPEG_SOURCE_DIR}"
        COMMENT "Building FFmpeg for Windows using MSYS2..."
        VERBATIM 
        USES_TERMINAL)

else()
    # Standard Windows build
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

# Copy avconfig.h
file (MAKE_DIRECTORY "${ffmpeg_output_dir}/include/libavutil")

file (COPY_FILE 
      "${FFMPEG_SOURCE_DIR}/libavutil/avconfig.h" 
      "${ffmpeg_output_dir}/include/libavutil/avconfig.h")

add_dependencies (ffmpeg ffmpeg_build_windows)

message (STATUS "Windows FFmpeg build configured successfully") 