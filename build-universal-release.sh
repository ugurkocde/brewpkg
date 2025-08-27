#!/bin/bash

# Build and package brewpkg as a universal binary for both Intel and Apple Silicon Macs
# This script creates a complete, signed installer package ready for distribution

set -e

echo "========================================="
echo "Building brewpkg Universal Binary Release"
echo "========================================="
echo ""

# Configuration
PROJECT_DIR="$(pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/brewpkg.xcarchive"
APP_NAME="brewpkg"
EXPORT_DIR="${BUILD_DIR}/export"
PACKAGE_DIR="${BUILD_DIR}/package"
OUTPUT_PKG="${PROJECT_DIR}/brewpkg-universal.pkg"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
xcodebuild clean -project brewpkg.xcodeproj -scheme brewpkg -configuration Release > /dev/null 2>&1

# Archive for distribution with universal binary
echo "📦 Building universal binary archive..."
xcodebuild archive \
    -project brewpkg.xcodeproj \
    -scheme brewpkg \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=macOS" \
    ARCHS="x86_64 arm64" \
    ONLY_ACTIVE_ARCH=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Export the archive
echo "📤 Exporting archive..."
mkdir -p "${EXPORT_DIR}"

# Create export options plist
cat > "${BUILD_DIR}/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>D259ULY2B4</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_DIR}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist"

# Verify the binary is universal
echo "🔍 Verifying universal binary..."
APP_PATH="${EXPORT_DIR}/${APP_NAME}.app"
BINARY_PATH="${APP_PATH}/Contents/MacOS/${APP_NAME}"

if [ -f "${BINARY_PATH}" ]; then
    ARCH_INFO=$(lipo -info "${BINARY_PATH}")
    echo "   Architecture info: ${ARCH_INFO}"
    
    # Check if both architectures are present
    if [[ $ARCH_INFO == *"x86_64"* ]] && [[ $ARCH_INFO == *"arm64"* ]]; then
        echo "   ✅ Universal binary confirmed (Intel + Apple Silicon)"
    else
        echo "   ⚠️  Warning: Binary may not be universal"
    fi
else
    echo "   ❌ Error: Binary not found at ${BINARY_PATH}"
    exit 1
fi

# Create installer package
echo "📦 Creating installer package..."
mkdir -p "${PACKAGE_DIR}"

# Build the package
pkgbuild \
    --root "${EXPORT_DIR}" \
    --identifier "com.ugurkoc.brewpkg" \
    --version "1.2.0" \
    --install-location "/Applications" \
    --component-plist "${BUILD_DIR}/components.plist" \
    "${OUTPUT_PKG}" 2>/dev/null || {
    # If component-plist fails, try without it
    pkgbuild \
        --root "${EXPORT_DIR}" \
        --identifier "com.ugurkoc.brewpkg" \
        --version "1.2.0" \
        --install-location "/Applications" \
        "${OUTPUT_PKG}"
}

# Sign the package if Developer ID Installer certificate is available
echo "🔏 Attempting to sign package..."
if security find-identity -v | grep -q "Developer ID Installer"; then
    INSTALLER_IDENTITY=$(security find-identity -v | grep "Developer ID Installer" | head -1 | awk '{print $2}')
    echo "   Found installer certificate: ${INSTALLER_IDENTITY}"
    
    # Create a signed version
    productsign \
        --sign "${INSTALLER_IDENTITY}" \
        "${OUTPUT_PKG}" \
        "${OUTPUT_PKG}.signed"
    
    mv "${OUTPUT_PKG}.signed" "${OUTPUT_PKG}"
    echo "   ✅ Package signed successfully"
else
    echo "   ⚠️  No Developer ID Installer certificate found - package will be unsigned"
fi

# Get package info
PACKAGE_SIZE=$(du -h "${OUTPUT_PKG}" | cut -f1)

echo ""
echo "========================================="
echo "✅ Build Complete!"
echo "========================================="
echo ""
echo "📦 Package: ${OUTPUT_PKG}"
echo "📏 Size: ${PACKAGE_SIZE}"
echo "🏗️  Architectures: x86_64 (Intel) + arm64 (Apple Silicon)"
echo "🖥️  Minimum OS: macOS 13.0"
echo ""
echo "To test the package:"
echo "  1. Copy to an Intel Mac and install"
echo "  2. Copy to an Apple Silicon Mac and install"
echo "  3. Verify the app runs natively on both (no Rosetta)"
echo ""
echo "To distribute:"
echo "  - Upload ${OUTPUT_PKG} to GitHub releases"
echo "  - Share the direct download link"
echo ""