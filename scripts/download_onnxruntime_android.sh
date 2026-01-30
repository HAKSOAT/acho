#!/usr/bin/env sh
#
# download_onnx_runtime.sh
#
# This build script was generated using an LLM to help with scripting runtime downloads.
#
# Usage: ./download_onnx_runtime.sh <abi> <api-level> [output-dir]
#

set -e  # Exit on error

# Function to get the Google Drive ID using a case statement
get_gdrive_id() {
    local key="$1"
    case "$key" in
        "arm64-v8a-27") echo "1q8SHkbCjDVQsuaNxJ9bpoi5MeBgpX2o1" ;;
        *) echo "" ;;
    esac
}

# Function to print usage
usage() {
    echo "Usage: $0 <abi> <api-level> [output-dir]"
    echo ""
    echo "Supported ABI/API level combinations:"
    echo "  - arm64-v8a-27"
    exit 1
}

# Function to download from Google Drive
download_from_gdrive() {
    local file_id="$1"
    local output_file="$2"
    
    echo "Downloading from Google Drive (ID: $file_id)..."
    echo "Saving to: $output_file"
    
    wget -q --show-progress \
        "https://drive.usercontent.google.com/download?export=download&confirm=t&id=${file_id}" \
        -O "${output_file}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Download successful: $output_file"
        return 0
    else
        echo "✗ Download failed"
        return 1
    fi
}

# Main script logic
main() {
    if [ $# -lt 2 ]; then
        usage
    fi
    
    local abi="$1"
    local api_level="$2"
    local output_dir="${3:-.}"
    
    mkdir -p "$output_dir"
    
    local lookup_key="${abi}-${api_level}"
    local gdrive_id=$(get_gdrive_id "$lookup_key")
    
    if [ -z "$gdrive_id" ]; then
        echo "Error: Unsupported ABI/API level combination: $abi/$api_level"
        echo ""
        usage
    fi
    
    local output_file="${output_dir}/onnxruntime-android-${abi}-api${api_level}/libonnxruntime.so"
    
    echo "Setting up environment for downloading ONNX Runtime..."
    echo "ABI: $abi"
    echo "API Level: $api_level"
    echo "Google Drive ID: $gdrive_id"
    echo ""
    
    mkdir -p "$(dirname "$output_file")"
    download_from_gdrive "$gdrive_id" "$output_file"
    
    echo ""
    echo "Download complete!"
    echo "File location: $output_file"
}

main "$@"
