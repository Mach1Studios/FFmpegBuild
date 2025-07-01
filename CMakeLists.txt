include_guard (GLOBAL)

cmake_minimum_required (VERSION 3.22 FATAL_ERROR)

project (
    FFmpeg
    VERSION 5.1.6
    DESCRIPTION "CMake build of FFmpeg"
    HOMEPAGE_URL "https://www.ffmpeg.org/"
    LANGUAGES NONE) # FFmpeg is built using make shell commands, so within CMake we don't need to enable any languages

enable_testing ()

# Platform detection and configuration
if (APPLE)
    if (CMAKE_OSX_ARCHITECTURES)
        if (arm64 IN_LIST CMAKE_OSX_ARCHITECTURES AND x86_64 IN_LIST CMAKE_OSX_ARCHITECTURES)
            set (univ_bin_default ON)
        else ()
            set (univ_bin_default OFF)
        endif ()
    else ()
        if (IOS)
            set (univ_bin_default OFF)
        else ()
            set (univ_bin_default ON)
        endif ()
    endif ()

    option (FFMPEG_MAC_UNIVERSAL_BINARY "Build a Mac universal binary" "${univ_bin_default}")
    set (FFMPEG_WINDOWS_BUILD OFF)
    set (FFMPEG_LINUX_BUILD OFF)
elseif (WIN32)
    set (FFMPEG_MAC_UNIVERSAL_BINARY OFF)
    option (FFMPEG_WINDOWS_BUILD "Build FFmpeg for Windows" ON)
    set (FFMPEG_LINUX_BUILD OFF)
    
    # Windows-specific options
    option (FFMPEG_WINDOWS_USE_MSYS2 "Use MSYS2/MinGW for Windows build" ON)
    option (FFMPEG_WINDOWS_CROSS_COMPILE "Cross-compile for Windows (from Linux/macOS)" OFF)
elseif (UNIX)
    set (FFMPEG_MAC_UNIVERSAL_BINARY OFF)
    set (FFMPEG_WINDOWS_BUILD OFF)
    option (FFMPEG_LINUX_BUILD "Build FFmpeg for Linux" ON)
    
    # Linux-specific options
    option (FFMPEG_LINUX_STATIC_BUILD "Build static libraries on Linux" OFF)
else()
    set (FFMPEG_MAC_UNIVERSAL_BINARY OFF)
    set (FFMPEG_WINDOWS_BUILD OFF)
    set (FFMPEG_LINUX_BUILD OFF)
    message(WARNING "Unsupported platform detected. Build may not work correctly.")
endif ()

# Cross-compilation options
option (FFMPEG_ENABLE_CROSS_COMPILATION "Enable cross-compilation support" OFF)

if (PROJECT_IS_TOP_LEVEL)
    set_property (
        GLOBAL PROPERTY
            USE_FOLDERS YES
            PREDEFINED_TARGETS_FOLDER Targets
            REPORT_UNDEFINED_PROPERTIES "${CMAKE_BINARY_DIR}/undefined_properties.log")

    set (CMAKE_FIND_PACKAGE_SORT_ORDER NATURAL)
    set (CMAKE_INSTALL_MESSAGE LAZY)
    set (CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION ON)

    # Need to enable at least one language for GNUInstallDirs
    enable_language (C)
endif ()

include (GNUInstallDirs)
include (FeatureSummary)

set (FFMPEG_INSTALL_DEST "${CMAKE_INSTALL_LIBDIR}/cmake/FFmpeg"
     CACHE STRING
           "Directory below INSTALL_PREFIX where FFmpeg CMake package files will be installed to")

# Platform-specific make executable detection
if (WIN32 AND FFMPEG_WINDOWS_USE_MSYS2)
    find_program (FFMPEG_MAKE_EXECUTABLE 
                  NAMES make.exe make
                  PATHS "C:/msys64/usr/bin" "C:/msys2/usr/bin" "D:/msys64/usr/bin" "D:/msys2/usr/bin"
                        "$ENV{MSYS2_ROOT}/usr/bin"
                  DOC "Path to the make executable used for building FFmpeg (MSYS2/MinGW)")
    
    if (NOT FFMPEG_MAKE_EXECUTABLE)
        message (FATAL_ERROR 
            "MSYS2 make not found. Please install MSYS2 and the build tools:\n"
            "1. Install MSYS2 from https://www.msys2.org/\n"
            "2. Open MSYS2 terminal and run: pacman -S base-devel mingw-w64-x86_64-toolchain\n"
            "3. Add MSYS2 to your PATH or set MSYS2_ROOT environment variable\n"
            "Alternatively, disable MSYS2: -DFFMPEG_WINDOWS_USE_MSYS2=OFF")
    endif()
else()
    find_program (FFMPEG_MAKE_EXECUTABLE 
                  NAMES make gmake nmake
                  DOC "Path to the make executable used for building FFmpeg"
                  REQUIRED)
endif()

set (FFMPEG_VERSION 5.1.6 CACHE STRING "FFmpeg version")

set (FFMPEG_NAME "ffmpeg-${FFMPEG_VERSION}")

set (cache_dir "${CMAKE_CURRENT_LIST_DIR}/Cache")

set (FFMPEG_SOURCE_DIR "${cache_dir}/${FFMPEG_NAME}" CACHE PATH "Path to FFmpeg source code")

mark_as_advanced (FORCE FFMPEG_VERSION FFMPEG_SOURCE_DIR FFMPEG_MAKE_EXECUTABLE FFMPEG_INSTALL_DEST)

# Download and extract FFmpeg source if needed
if (NOT EXISTS "${FFMPEG_SOURCE_DIR}")

    set (FFMPEG_URL "https://ffmpeg.org/releases/${FFMPEG_NAME}.tar.bz2")

    get_filename_component (FFMPEG_ARCHIVE_NAME "${FFMPEG_URL}" NAME)

    set (ffmpeg_tarball "${cache_dir}/${FFMPEG_ARCHIVE_NAME}")

    if(NOT EXISTS "${ffmpeg_tarball}")
        message (STATUS "Downloading FFmpeg sources from ${FFMPEG_URL} to ${FFMPEG_SOURCE_DIR}...")

        file (DOWNLOAD "${FFMPEG_URL}" "${ffmpeg_tarball}")
    endif()

    message (VERBOSE "Unpacking ffmpeg tarball...")

    execute_process (COMMAND "${CMAKE_COMMAND}" -E tar xzf "${ffmpeg_tarball}"
                     WORKING_DIRECTORY "${cache_dir}")
endif ()

# Platform-specific linker flags
string (REPLACE " -Wl,--fatal-warnings" "" FFMPEG_LD_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
set (FFMPEG_LD_FLAGS "${FFMPEG_C_FLAGS} ${FFMPEG_LD_FLAGS} ${FFMPEG_EXTRA_LD_FLAGS}")

# Include build configuration
include ("${CMAKE_CURRENT_LIST_DIR}/cmake/ConfigureFFmpegBuild.cmake")

add_library (ffmpeg INTERFACE)

set (ffmpeg_output_dir "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg")

message (DEBUG "ffmpeg output dir: ${ffmpeg_output_dir}")

# Platform-specific build logic
if (FFMPEG_MAC_UNIVERSAL_BINARY)
    include ("${CMAKE_CURRENT_LIST_DIR}/cmake/FFmpegMacBuild.cmake")
elseif (FFMPEG_WINDOWS_BUILD)
    include ("${CMAKE_CURRENT_LIST_DIR}/cmake/FFmpegWindowsBuild.cmake")
elseif (FFMPEG_LINUX_BUILD)
    include ("${CMAKE_CURRENT_LIST_DIR}/cmake/FFmpegLinuxBuild.cmake")
else ()
    message (STATUS "Configuring FFmpeg build for current platform...")

    if (PROJECT_IS_TOP_LEVEL)
        set (all_flag ALL)
    else ()
        unset (all_flag)
    endif ()

    preconfigure_ffmpeg_build (SOURCE_DIR "${FFMPEG_SOURCE_DIR}" 
                               OUTPUT_DIR "${ffmpeg_output_dir}")

    create_ffmpeg_build_target (SOURCE_DIR "${FFMPEG_SOURCE_DIR}" 
                                OUTPUT_DIR "${ffmpeg_output_dir}"
                                BUILD_TARGET ffmpeg_build 
                                ${all_flag})

    # avconfig.h is generated by the configure script, need to manually copy it to the output directory...
    
    file (MAKE_DIRECTORY "${ffmpeg_output_dir}/include/libavutil")

    file (COPY_FILE 
            "${FFMPEG_SOURCE_DIR}/libavutil/avconfig.h" 
            "${ffmpeg_output_dir}/include/libavutil/avconfig.h")
endif ()

# Copy headers for all platforms
file (GLOB lib_headers ${FFMPEG_SOURCE_DIR}/lib*)

file (COPY ${lib_headers} "${FFMPEG_SOURCE_DIR}/compat"
      DESTINATION "${ffmpeg_output_dir}/include" FILES_MATCHING PATTERN *.h)

# Feature reporting
add_feature_info ("FFmpeg Mac universal binary" 
                  "${FFMPEG_MAC_UNIVERSAL_BINARY}" 
                  "Mac universal binary build of ffmpeg")

add_feature_info ("FFmpeg Windows build" 
                  "${FFMPEG_WINDOWS_BUILD}" 
                  "Windows build of ffmpeg")

add_feature_info ("FFmpeg Linux build" 
                  "${FFMPEG_LINUX_BUILD}" 
                  "Linux build of ffmpeg")

add_feature_info ("FFmpeg MSYS2 support" 
                  "${FFMPEG_WINDOWS_USE_MSYS2}" 
                  "Use MSYS2/MinGW for Windows builds")

target_include_directories (
    ffmpeg
    INTERFACE "$<BUILD_INTERFACE:${ffmpeg_output_dir}/include>"
              "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/ffmpeg>")

get_property (debug_configs GLOBAL PROPERTY DEBUG_CONFIGURATIONS)

if (NOT debug_configs)
    set (debug_configs Debug)
endif ()

set (config_is_debug "$<IN_LIST:$<CONFIG>,${debug_configs}>")

set (compiler_msvc "$<C_COMPILER_ID:MSVC>")

# Platform-specific compiler settings
# see https://www.ffmpeg.org/platform.html#toc-Linking-to-FFmpeg-with-Microsoft-Visual-C_002b_002b
if (WIN32)
    set_target_properties (ffmpeg PROPERTIES 
                            $<${compiler_msvc}:MSVC_RUNTIME_LIBRARY MultiThreaded$<${config_is_debug}:Debug>>)
    
    target_compile_options (ffmpeg INTERFACE "$<${compiler_msvc}:/MT>")
endif()

add_library (ffmpeg::ffmpeg ALIAS ffmpeg)

install (
    DIRECTORY "${ffmpeg_output_dir}/include"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ffmpeg"
    COMPONENT ffmpeg_base
    FILES_MATCHING PATTERN *.h)

include (CPackComponent)

cpack_add_component (ffmpeg_base HIDDEN)

cpack_add_component_group (ffmpeg DISPLAY_NAME "All FFmpeg libraries" BOLD_TITLE)

install (
    TARGETS ffmpeg
    EXPORT FFmpegTargets
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT ffmpeg_base
    NAMELINK_COMPONENT ffmpeg_base
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" COMPONENT ffmpeg_base
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT ffmpeg_base
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ffmpeg")

install (EXPORT FFmpegTargets NAMESPACE ffmpeg:: 
         DESTINATION "${FFMPEG_INSTALL_DEST}"
         COMPONENT ffmpeg_base)

#

include (CMakePackageConfigHelpers)

write_basic_package_version_file (ffmpeg-config-version.cmake
                                  VERSION "${PROJECT_VERSION}"
                                  COMPATIBILITY SameMajorVersion)

configure_package_config_file (cmake/ffmpeg-config.cmake ffmpeg-config.cmake
                               INSTALL_DESTINATION "${FFMPEG_INSTALL_DEST}"
                               NO_SET_AND_CHECK_MACRO)

install (FILES "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-config-version.cmake"
               "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-config.cmake"
         DESTINATION "${FFMPEG_INSTALL_DEST}" 
         COMPONENT ffmpeg_base)

export (PACKAGE FFmpeg)
