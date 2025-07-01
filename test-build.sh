#!/bin/bash

# FFmpeg Cross-Platform Build Test Script
# This script tests the build system on different configurations

set -e

echo "=== FFmpeg Cross-Platform Build Test ==="
echo

# Parse command line arguments
PLATFORM_FILTER=""
COMPREHENSIVE_TEST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM_FILTER="$2"
            shift 2
            ;;
        --all-platforms)
            COMPREHENSIVE_TEST=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --platform <name>     Test specific platform (macos, linux, windows)"
            echo "  --all-platforms       Test all platform configurations (may fail on unsupported platforms)"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get the current platform
case "$(uname -s)" in
    Darwin)
        HOST_PLATFORM="macOS"
        ;;
    Linux)
        HOST_PLATFORM="Linux"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        HOST_PLATFORM="Windows"
        ;;
    *)
        HOST_PLATFORM="Unknown"
        ;;
esac

echo "Host platform: $HOST_PLATFORM"

# Determine which platforms to test
PLATFORMS_TO_TEST=()

if [ "$COMPREHENSIVE_TEST" = true ]; then
    echo "Running comprehensive test for all platforms..."
    PLATFORMS_TO_TEST=("macOS" "Linux" "Windows")
elif [ -n "$PLATFORM_FILTER" ]; then
    echo "Testing specific platform: $PLATFORM_FILTER"
    case "$PLATFORM_FILTER" in
        macos|macOS)
            PLATFORMS_TO_TEST=("macOS")
            ;;
        linux|Linux)
            PLATFORMS_TO_TEST=("Linux")
            ;;
        windows|Windows)
            PLATFORMS_TO_TEST=("Windows")
            ;;
        *)
            echo "Unknown platform: $PLATFORM_FILTER"
            echo "Supported platforms: macos, linux, windows"
            exit 1
            ;;
    esac
else
    echo "Testing current platform only: $HOST_PLATFORM"
    PLATFORMS_TO_TEST=("$HOST_PLATFORM")
fi

# Create test build directory
TEST_DIR="test-build-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Testing in directory: $TEST_DIR"
echo

# Test counter
TEST_COUNT=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local should_succeed="${3:-true}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    echo "--- Test $TEST_COUNT: $test_name ---"
    
    # Clean previous configuration
    rm -f CMakeCache.txt
    rm -rf CMakeFiles/
    
    if [ "$should_succeed" = true ]; then
        if eval "$test_command"; then
            echo "✓ $test_name: PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "✗ $test_name: FAILED"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        if eval "$test_command" 2>/dev/null; then
            echo "✗ $test_name: FAILED (expected to fail but succeeded)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        else
            echo "✓ $test_name: PASSED (expected failure)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        fi
    fi
    echo
}

# Test 1: Basic configuration
run_test "Basic Configuration" "cmake .. -DCMAKE_BUILD_TYPE=Release"

# Test platform-specific configurations
for platform in "${PLATFORMS_TO_TEST[@]}"; do
    case "$platform" in
        macOS)
            # Test standard macOS build
            run_test "macOS Standard Build" "cmake .. -DFFMPEG_MAC_UNIVERSAL_BINARY=OFF -DCMAKE_BUILD_TYPE=Release"
            
            # Test universal binary (may fail on non-macOS hosts)
            if [ "$HOST_PLATFORM" = "macOS" ]; then
                run_test "macOS Universal Binary" "cmake .. -DFFMPEG_MAC_UNIVERSAL_BINARY=ON -DCMAKE_BUILD_TYPE=Release"
            else
                echo "--- Skipping macOS Universal Binary test (not on macOS host) ---"
                echo "ℹ This test requires macOS host with Xcode tools"
                echo
            fi
            ;;
            
        Linux)
            # Test Linux shared build
            run_test "Linux Shared Build" "cmake .. -DFFMPEG_LINUX_BUILD=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release"
            
            # Test Linux static build
            run_test "Linux Static Build" "cmake .. -DFFMPEG_LINUX_BUILD=ON -DFFMPEG_LINUX_STATIC_BUILD=ON -DCMAKE_BUILD_TYPE=Release"
            ;;
            
        Windows)
            # Test Windows MSYS2 build
            if [ "$HOST_PLATFORM" = "Windows" ] || command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
                run_test "Windows MSYS2 Build" "cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_USE_MSYS2=ON -DCMAKE_BUILD_TYPE=Release"
            else
                echo "--- Skipping Windows MSYS2 test (no Windows environment or MinGW cross-compiler) ---"
                echo "ℹ This test requires Windows with MSYS2 or MinGW cross-compiler"
                echo
            fi
            
            # Test Windows cross-compilation configuration
            if [ "$HOST_PLATFORM" != "Windows" ]; then
                run_test "Windows Cross-compilation Config" "cmake .. -DFFMPEG_WINDOWS_BUILD=ON -DFFMPEG_WINDOWS_CROSS_COMPILE=ON -DCMAKE_BUILD_TYPE=Release"
            fi
            ;;
    esac
done

# Test invalid configurations (should fail)
run_test "Invalid Configuration (Multiple Platforms)" "cmake .. -DFFMPEG_LINUX_BUILD=ON -DFFMPEG_WINDOWS_BUILD=ON -DCMAKE_BUILD_TYPE=Release" false

# Test feature detection
echo "--- Feature Detection Test ---"
echo "Checking for key CMake variables..."

if [ -f "CMakeCache.txt" ]; then
    echo "✓ CMakeCache.txt exists"
    
    # Check for key variables
    declare -a required_vars=("FFMPEG_VERSION" "FFMPEG_SOURCE_DIR" "FFMPEG_MAKE_EXECUTABLE")
    
    for var in "${required_vars[@]}"; do
        if grep -q "$var" CMakeCache.txt; then
            echo "✓ $var found"
        else
            echo "✗ $var not found"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    done
    
    PASSED_TESTS=$((PASSED_TESTS + ${#required_vars[@]}))
else
    echo "✗ CMakeCache.txt not found"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo

# Test cache directory creation
echo "--- Cache Directory Test ---"
if [ -d "../Cache" ]; then
    echo "✓ Cache directory exists"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    
    if ls ../Cache/ffmpeg-*.tar.bz2 >/dev/null 2>&1 || ls -d ../Cache/ffmpeg-*/ >/dev/null 2>&1; then
        echo "✓ FFmpeg source files found in cache"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "ℹ FFmpeg source files not yet downloaded (will be downloaded on first build)"
    fi
else
    echo "ℹ Cache directory will be created on first build"
fi
echo

# Print final summary
echo "=== Test Summary ==="
echo "Total tests run: $((PASSED_TESTS + FAILED_TESTS))"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All tests passed! Build system is ready."
    echo
    echo "Platform-specific build instructions:"
    echo
    case "$HOST_PLATFORM" in
        macOS)
            echo "For macOS:"
            echo "  cmake --build . --config Release"
            ;;
        Linux)
            echo "For Linux:"
            echo "  cmake --build . --config Release"
            ;;
        Windows)
            echo "For Windows:"
            echo "  cmake --build . --config Release"
            echo "  (Make sure MSYS2 is in your PATH)"
            ;;
    esac
else
    echo "❌ Some tests failed. Check the output above for details."
    echo
    echo "Common issues:"
    echo "- Missing platform-specific tools (MSYS2, Xcode, GCC/Clang)"
    echo "- Cross-compilation tools not installed"
    echo "- Platform mismatch for certain features"
fi

echo
echo "To clean up this test:"
echo "  cd .. && rm -rf $TEST_DIR"

exit $FAILED_TESTS 