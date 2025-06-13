#!/bin/bash

set -e

# CI Build Script
# Usage: ./build.sh [--dev|--release] [--compress|--no-compress]
# Environment variables:
#   OPENLIST_FRONTEND_BUILD_MODE=dev|release (default: dev)
#   OPENLIST_FRONTEND_BUILD_COMPRESS=true|false (default: false)

# Set defaults from environment variables
BUILD_TYPE=${OPENLIST_FRONTEND_BUILD_MODE:-dev}
COMPRESS_FLAG=${OPENLIST_FRONTEND_BUILD_COMPRESS:-false}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            BUILD_TYPE="dev"
            shift
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --compress)
            COMPRESS_FLAG="true"
            shift
            ;;
        --no-compress)
            COMPRESS_FLAG="false"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dev|--release] [--compress|--no-compress]"
            echo ""
            echo "Options:"
            echo "  --dev         Build development version (no version change)"
            echo "  --release     Build release version (update version from git tags)"
            echo "  --compress    Create compressed archive"
            echo "  --no-compress Skip compression (default)"
            echo ""
            echo "Environment variables:"
            echo "  OPENLIST_FRONTEND_BUILD_MODE=dev|release (default: dev)"
            echo "  OPENLIST_FRONTEND_BUILD_COMPRESS=true|false (default: false)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$BUILD_TYPE" == "dev" ]; then
    echo "Building DEV version..."
    # For dev build, keep version as is
    # Get version and commit for dev build
    version=$(git describe --abbrev=0 --tags 2>/dev/null || echo "v0.0.0")
    commit=$(git rev-parse --short HEAD)
    version_clean=${version#v}
    archive_name="openlist-frontend-dist-v${version_clean}-${commit}"
elif [ "$BUILD_TYPE" == "release" ]; then
    echo "Building RELEASE version..."
    # replace version for release build
    version=$(git describe --abbrev=0 --tags 2>/dev/null || echo "v0.0.0")
    version_clean=${version#v}
    archive_name="openlist-frontend-dist-v${version_clean}"
    
    echo "Git version found: $version"
    echo "Cleaned version: $version_clean"
    
    # Replace version in package.json
    if grep -q '"version": "0.0.0"' package.json; then
        sed -i -e "s/\"version\": \"0.0.0\"/\"version\": \"$version_clean\"/g" package.json
        echo "Version updated successfully"
    else
        echo "Warning: Could not find '\"version\": \"0.0.0\"' pattern in package.json"
        echo "Current version line:"
        grep '"version":' package.json || echo "No version field found"
    fi
    
    echo "Current package.json version:"
    grep '"version":' package.json
else
    echo "Invalid build type: $BUILD_TYPE"
    echo "Use --help for usage information"
    exit 1
fi

echo "Archive name will be: ${archive_name}.tar.gz"

# build
pnpm install
pnpm i18n:release
pnpm build

# handle compression if requested
if [ "$COMPRESS_FLAG" == "true" ]; then
    echo "Creating compressed archive..."
    
    # Use the archive name determined earlier
    tar -czvf "${archive_name}.tar.gz" -C dist .
    mv "${archive_name}.tar.gz" dist/
    echo "Build with compression completed. File created:"
    echo "- dist/${archive_name}.tar.gz"
else
    echo "Build completed without compression."
fi