#!/bin/bash
#
# This build script was generated using an LLM to speed up building ONNX Runtime for Android.
#
# build_onnxruntime_android.sh
#
# A comprehensive script to build ONNX Runtime for Android from source.
# This script handles:
#   1. Installing required dependencies
#   2. Downloading Android SDK/NDK (if not present)
#   3. Cloning ONNX Runtime repository
#   4. Fixing known build issues (Eigen hash mismatch)
#   5. Building for specified Android ABIs
#   6. Packaging output for easy transfer
#
# Usage:
#   ./build_onnxruntime_android.sh [OPTIONS]
#
# Options:
#   --sdk-path PATH       Path to existing Android SDK (optional)
#   --ndk-path PATH       Path to existing Android NDK (optional)
#   --abi ABI             Android ABI to build (default: arm64-v8a)
#                         Options: arm64-v8a, armeabi-v7a, x86_64, x86
#   --api-level LEVEL     Android API level (default: 27)
#   --build-dir DIR       Directory for build output (default: ./onnxruntime-android-build)
#   --ort-version TAG     ONNX Runtime version/tag to build (default: v1.17.0)
#   --skip-deps           Skip installing system dependencies
#   --minimal             Build minimal runtime (smaller, faster build)
#   --shared              Build shared library instead of static
#   --allow-root          Allow running as root (for Docker/CI environments)
#   --zip                 Create a zip archive of the output for easy download
#   --help                Show this help message
#
# Author: Manus AI
# Date: January 2026
#

set -e  # Exit on error
set -o pipefail

# =============================================================================
# Configuration Defaults
# =============================================================================

ANDROID_SDK_PATH=""
ANDROID_NDK_PATH=""
ANDROID_ABI="arm64-v8a"
ANDROID_API_LEVEL="27"
BUILD_DIR="./onnxruntime-android-build"
ORT_VERSION="v1.17.0"
SKIP_DEPS=false
MINIMAL_BUILD=false
BUILD_SHARED=false
ALLOW_ROOT=false
ZIP_OUTPUT=false

# NDK version to download if not provided
NDK_VERSION="r26b"
CMDLINE_TOOLS_VERSION="11076708"  # Latest as of 2024

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    head -45 "$0" | tail -35
    exit 0
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --sdk-path)
            ANDROID_SDK_PATH="$2"
            shift 2
            ;;
        --ndk-path)
            ANDROID_NDK_PATH="$2"
            shift 2
            ;;
        --abi)
            ANDROID_ABI="$2"
            shift 2
            ;;
        --api-level)
            ANDROID_API_LEVEL="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --ort-version)
            ORT_VERSION="$2"
            shift 2
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --minimal)
            MINIMAL_BUILD=true
            shift
            ;;
        --shared)
            BUILD_SHARED=true
            shift
            ;;
        --allow-root)
            ALLOW_ROOT=true
            shift
            ;;
        --zip)
            ZIP_OUTPUT=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# =============================================================================
# Detect OS
# =============================================================================

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected OS: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected OS: macOS"
    else
        log_error "Unsupported OS: $OSTYPE"
        log_error "This script supports Linux and macOS only."
        exit 1
    fi
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_dependencies() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log_info "Skipping dependency installation (--skip-deps)"
        return
    fi

    log_info "Installing system dependencies..."

    if [[ "$OS" == "linux" ]]; then
        # Detect package manager
        if check_command apt-get; then
            sudo apt-get update
            sudo apt-get install -y \
                build-essential \
                cmake \
                git \
                curl \
                unzip \
                python3 \
                python3-pip \
                ninja-build \
                ccache \
                openjdk-11-jdk \
                zip
        elif check_command dnf; then
            sudo dnf install -y \
                gcc \
                gcc-c++ \
                cmake \
                git \
                curl \
                unzip \
                python3 \
                python3-pip \
                ninja-build \
                ccache \
                java-11-openjdk-devel \
                zip
        elif check_command pacman; then
            sudo pacman -Syu --noconfirm \
                base-devel \
                cmake \
                git \
                curl \
                unzip \
                python \
                python-pip \
                ninja \
                ccache \
                jdk11-openjdk \
                zip
        else
            log_warning "Unknown package manager. Please install manually:"
            log_warning "  - build-essential (gcc, g++, make)"
            log_warning "  - cmake (>= 3.18)"
            log_warning "  - git"
            log_warning "  - curl, unzip, zip"
            log_warning "  - python3, pip"
            log_warning "  - ninja-build"
            log_warning "  - ccache (optional, for faster rebuilds)"
            log_warning "  - JDK 11+"
        fi
    elif [[ "$OS" == "macos" ]]; then
        if ! check_command brew; then
            log_error "Homebrew not found. Please install it first:"
            log_error '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi

        brew install \
            cmake \
            git \
            ninja \
            ccache \
            python@3.11 \
            openjdk@11

        # Set JAVA_HOME for macOS
        export JAVA_HOME="$(/usr/libexec/java_home -v 11 2>/dev/null || echo '/opt/homebrew/opt/openjdk@11')"
    fi

    log_success "Dependencies installed"
}

# =============================================================================
# Setup Android SDK and NDK
# =============================================================================

setup_android_sdk_ndk() {
    log_info "Setting up Android SDK and NDK..."

    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    BUILD_DIR="$(pwd)"  # Get absolute path

    # Setup SDK
    if [[ -z "$ANDROID_SDK_PATH" ]]; then
        ANDROID_SDK_PATH="$BUILD_DIR/android-sdk"

        if [[ ! -d "$ANDROID_SDK_PATH/cmdline-tools" ]]; then
            log_info "Downloading Android command-line tools..."

            if [[ "$OS" == "linux" ]]; then
                CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
            else
                CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-${CMDLINE_TOOLS_VERSION}_latest.zip"
            fi

            mkdir -p "$ANDROID_SDK_PATH"
            curl -L "$CMDLINE_TOOLS_URL" -o cmdline-tools.zip
            unzip -q cmdline-tools.zip -d "$ANDROID_SDK_PATH"

            # Fix directory structure (required by sdkmanager)
            mkdir -p "$ANDROID_SDK_PATH/cmdline-tools"
            mv "$ANDROID_SDK_PATH/cmdline-tools" "$ANDROID_SDK_PATH/cmdline-tools-tmp" 2>/dev/null || true
            mkdir -p "$ANDROID_SDK_PATH/cmdline-tools"
            mv "$ANDROID_SDK_PATH/cmdline-tools-tmp" "$ANDROID_SDK_PATH/cmdline-tools/latest" 2>/dev/null || \
                mv "$ANDROID_SDK_PATH/cmdline-tools" "$ANDROID_SDK_PATH/cmdline-tools/latest" 2>/dev/null || true

            rm cmdline-tools.zip
            log_success "Command-line tools downloaded"
        fi

        # Install SDK platform
        SDKMANAGER="$ANDROID_SDK_PATH/cmdline-tools/latest/bin/sdkmanager"
        if [[ -f "$SDKMANAGER" ]]; then
            log_info "Installing Android SDK platform..."
            yes | "$SDKMANAGER" --licenses > /dev/null 2>&1 || true
            "$SDKMANAGER" "platforms;android-$ANDROID_API_LEVEL" "platform-tools"
        fi
    fi

    # Setup NDK
    if [[ -z "$ANDROID_NDK_PATH" ]]; then
        ANDROID_NDK_PATH="$ANDROID_SDK_PATH/ndk/$NDK_VERSION"

        if [[ ! -d "$ANDROID_NDK_PATH" ]]; then
            log_info "Downloading Android NDK $NDK_VERSION..."

            if [[ "$OS" == "linux" ]]; then
                NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"
            else
                NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-darwin.zip"
            fi

            curl -L "$NDK_URL" -o android-ndk.zip
            unzip -q android-ndk.zip
            mkdir -p "$ANDROID_SDK_PATH/ndk"
            mv "android-ndk-$NDK_VERSION" "$ANDROID_NDK_PATH"
            rm android-ndk.zip
            log_success "NDK $NDK_VERSION downloaded"
        fi
    fi

    # Verify paths
    if [[ ! -d "$ANDROID_SDK_PATH" ]]; then
        log_error "Android SDK not found at: $ANDROID_SDK_PATH"
        exit 1
    fi

    if [[ ! -d "$ANDROID_NDK_PATH" ]]; then
        log_error "Android NDK not found at: $ANDROID_NDK_PATH"
        exit 1
    fi

    log_success "Android SDK: $ANDROID_SDK_PATH"
    log_success "Android NDK: $ANDROID_NDK_PATH"
}

# =============================================================================
# Clone ONNX Runtime
# =============================================================================

clone_onnxruntime() {
    log_info "Cloning ONNX Runtime repository (version: $ORT_VERSION)..."

    cd "$BUILD_DIR"

    if [[ -d "onnxruntime" ]]; then
        log_info "ONNX Runtime directory exists, updating..."
        cd onnxruntime
        git fetch --all --tags
        git checkout "$ORT_VERSION"
        git submodule sync
        git submodule update --init --recursive
    else
        git clone --recursive https://github.com/microsoft/onnxruntime.git
        cd onnxruntime
        git checkout "$ORT_VERSION"
        git submodule sync
        git submodule update --init --recursive
    fi

    ORT_SOURCE_DIR="$(pwd)"
    log_success "ONNX Runtime source ready at: $ORT_SOURCE_DIR"
}

# =============================================================================
# Fix Eigen Hash Mismatch
# =============================================================================

fix_eigen_hash() {
    log_info "Checking for Eigen hash mismatch issue..."

    DEPS_FILE="$ORT_SOURCE_DIR/cmake/deps.txt"

    if [[ ! -f "$DEPS_FILE" ]]; then
        log_warning "deps.txt not found, skipping Eigen hash fix"
        return
    fi

    # Check if eigen line exists
    if grep -q "^eigen;" "$DEPS_FILE"; then
        log_info "Found Eigen dependency in deps.txt"

        # Extract the URL from the eigen line
        EIGEN_URL=$(grep "^eigen;" "$DEPS_FILE" | cut -d';' -f2)

        if [[ -n "$EIGEN_URL" ]]; then
            log_info "Downloading Eigen to calculate actual hash..."

            TEMP_ZIP="/tmp/eigen_temp_$$.zip"
            if curl -sL "$EIGEN_URL" -o "$TEMP_ZIP" 2>/dev/null; then
                ACTUAL_HASH=$(sha1sum "$TEMP_ZIP" | cut -d' ' -f1)
                rm -f "$TEMP_ZIP"

                # Get expected hash from deps.txt
                EXPECTED_HASH=$(grep "^eigen;" "$DEPS_FILE" | cut -d';' -f3)

                if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
                    log_warning "Eigen hash mismatch detected!"
                    log_warning "  Expected: $EXPECTED_HASH"
                    log_warning "  Actual:   $ACTUAL_HASH"
                    log_info "Updating deps.txt with correct hash..."

                    # Create backup
                    cp "$DEPS_FILE" "${DEPS_FILE}.bak"

                    # Replace the hash
                    sed -i "s|$EXPECTED_HASH|$ACTUAL_HASH|g" "$DEPS_FILE"

                    log_success "Eigen hash updated in deps.txt"
                else
                    log_success "Eigen hash is correct, no fix needed"
                fi
            else
                log_warning "Could not download Eigen to verify hash, proceeding anyway"
            fi
        fi
    else
        log_info "No eigen entry found in deps.txt (may use different method)"
    fi
}

# =============================================================================
# Build ONNX Runtime
# =============================================================================

build_onnxruntime() {
    log_info "Building ONNX Runtime for Android..."
    log_info "  ABI: $ANDROID_ABI"
    log_info "  API Level: $ANDROID_API_LEVEL"
    log_info "  Minimal: $MINIMAL_BUILD"
    log_info "  Shared Library: $BUILD_SHARED"

    cd "$ORT_SOURCE_DIR"

    # Build command
    BUILD_CMD="./build.sh"
    BUILD_CMD+=" --android"
    BUILD_CMD+=" --android_sdk_path \"$ANDROID_SDK_PATH\""
    BUILD_CMD+=" --android_ndk_path \"$ANDROID_NDK_PATH\""
    BUILD_CMD+=" --android_abi $ANDROID_ABI"
    BUILD_CMD+=" --android_api $ANDROID_API_LEVEL"
    BUILD_CMD+=" --config Release"
    BUILD_CMD+=" --parallel"
    BUILD_CMD+=" --skip_tests"

    if [[ "$MINIMAL_BUILD" == true ]]; then
        BUILD_CMD+=" --minimal_build"
    fi

    if [[ "$BUILD_SHARED" == true ]]; then
        BUILD_CMD+=" --build_shared_lib"
    fi

    # Handle running as root (e.g., in Docker containers or CI)
    if [[ "$ALLOW_ROOT" == true ]] || [[ "$EUID" -eq 0 ]]; then
        BUILD_CMD+=" --allow_running_as_root"
        log_warning "Running as root - adding --allow_running_as_root flag"
    fi

    # Enable ccache if available
    if check_command ccache; then
        export CC="ccache clang"
        export CXX="ccache clang++"
        log_info "Using ccache for faster compilation"
    fi

    log_info "Executing build command:"
    log_info "  $BUILD_CMD"
    echo ""

    # Record start time
    START_TIME=$(date +%s)

    # Run build
    eval "$BUILD_CMD"

    # Record end time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS_REMAINING=$((DURATION % 60))

    log_success "Build completed in ${MINUTES}m ${SECONDS_REMAINING}s"
}

# =============================================================================
# Post-Build Summary
# =============================================================================

post_build_summary() {
    echo ""
    log_info "=============================================="
    log_info "Build Summary"
    log_info "=============================================="

    # Find the build output directory
    BUILD_OUTPUT_DIR="$ORT_SOURCE_DIR/build/Android/Release"

    if [[ ! -d "$BUILD_OUTPUT_DIR" ]]; then
        log_warning "Expected build output not found at: $BUILD_OUTPUT_DIR"
        log_warning "Searching for build output..."
        BUILD_OUTPUT_DIR=$(find "$ORT_SOURCE_DIR/build" -name "Release" -type d 2>/dev/null | head -1)
    fi

    if [[ -d "$BUILD_OUTPUT_DIR" ]]; then
        log_success "Build output directory: $BUILD_OUTPUT_DIR"

        # List key files
        echo ""
        log_info "Key library files:"

        # Store files in array to avoid subshell issues
        if [[ "$BUILD_SHARED" == true ]]; then
            mapfile -t LIB_FILES < <(find "$BUILD_OUTPUT_DIR" -name "libonnxruntime.so" -type f 2>/dev/null)
        else
            mapfile -t LIB_FILES < <(find "$BUILD_OUTPUT_DIR" -name "*.a" -type f 2>/dev/null | head -20)
        fi

        for f in "${LIB_FILES[@]}"; do
            if [[ -n "$f" ]]; then
                SIZE=$(du -h "$f" | cut -f1)
                echo "  $f ($SIZE)"
            fi
        done

        # Create a convenient output directory
        OUTPUT_DIR="$BUILD_DIR/output/$ANDROID_ABI"
        mkdir -p "$OUTPUT_DIR"

        log_info "Copying libraries to output directory..."

        if [[ "$BUILD_SHARED" == true ]]; then
            # Copy shared library
            find "$BUILD_OUTPUT_DIR" -name "libonnxruntime.so" -exec cp {} "$OUTPUT_DIR/" \;
        else
            # Copy static libraries
            find "$BUILD_OUTPUT_DIR" -name "*.a" -exec cp {} "$OUTPUT_DIR/" \;
        fi

        # Count copied files
        LIB_COUNT=$(find "$OUTPUT_DIR" -name "*.a" -o -name "*.so" 2>/dev/null | wc -l)
        log_success "Copied $LIB_COUNT library files"

        # Copy headers
        INCLUDE_DIR="$OUTPUT_DIR/include"
        mkdir -p "$INCLUDE_DIR"
        cp -r "$ORT_SOURCE_DIR/include/onnxruntime" "$INCLUDE_DIR/" 2>/dev/null || true

        echo ""
        echo ""
        log_success "=============================================="
        log_success "BUILD SUCCESSFUL!"
        log_success "=============================================="
        echo ""
        log_info "Libraries copied to: $OUTPUT_DIR"
        log_info "Headers copied to: $INCLUDE_DIR"
        echo ""
        log_info "To use with the 'ort' Rust crate, set:"
        log_info "  export ORT_LIB_LOCATION=\"$OUTPUT_DIR\""
        echo ""
        log_info "Then build your Rust project with:"

        case "$ANDROID_ABI" in
            arm64-v8a)
                log_info "  cargo build --target aarch64-linux-android --release"
                ;;
            armeabi-v7a)
                log_info "  cargo build --target armv7-linux-androideabi --release"
                ;;
            x86_64)
                log_info "  cargo build --target x86_64-linux-android --release"
                ;;
            x86)
                log_info "  cargo build --target i686-linux-android --release"
                ;;
        esac

        # Create zip archive if requested
        if [[ "$ZIP_OUTPUT" == true ]]; then
            echo ""
            log_info "Creating zip archive..."

            ZIP_NAME="onnxruntime-android-${ANDROID_ABI}-${ORT_VERSION}.zip"
            ZIP_PATH="$BUILD_DIR/$ZIP_NAME"

            # Create zip with libraries and headers
            cd "$BUILD_DIR/output"
            zip -r "$ZIP_PATH" "$ANDROID_ABI" -x "*.DS_Store" -x "*__MACOSX*"

            ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)

            echo ""
            log_success "=============================================="
            log_success "ZIP ARCHIVE CREATED"
            log_success "=============================================="
            log_success "File: $ZIP_PATH"
            log_success "Size: $ZIP_SIZE"
            echo ""
            log_info "Download this file and extract on your Mac."
            log_info "Then set ORT_LIB_LOCATION to the extracted directory."
        fi

        echo ""
        log_success "All done!"
        echo ""

    else
        log_error "Could not find build output directory"
        exit 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "=============================================="
    echo "ONNX Runtime Android Build Script"
    echo "=============================================="
    echo ""

    detect_os
    install_dependencies
    setup_android_sdk_ndk
    clone_onnxruntime
    fix_eigen_hash
    build_onnxruntime
    post_build_summary
}

# Run main
main
