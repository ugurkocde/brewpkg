#!/bin/bash

# create-pkg.sh - Creates a signed installer package for brewpkg
# Usage: ./create-pkg.sh <app-path> <output-pkg-path>

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <app-path> <output-pkg-path>"
    echo "Example: $0 'build/Build/Products/Release/brewpkg.app' 'brewpkg.pkg'"
    exit 1
fi

APP_PATH="$1"
OUTPUT_PKG="$2"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Extract app information
APP_NAME=$(basename "$APP_PATH" .app)
BUNDLE_ID=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "com.ugurkoc.brewpkg")
VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")

echo "Creating installer package for $APP_NAME"
echo "Bundle ID: $BUNDLE_ID"
echo "Version: $VERSION"

# Create temporary directory for package building
TEMP_DIR=$(mktemp -d)
SCRIPTS_DIR="$TEMP_DIR/scripts"
ROOT_DIR="$TEMP_DIR/root"

# Create directory structure
mkdir -p "$ROOT_DIR/Applications"
mkdir -p "$SCRIPTS_DIR"

# Copy app to temporary location
echo "Copying app to package root..."
cp -R "$APP_PATH" "$ROOT_DIR/Applications/"

# Create postinstall script to set proper permissions
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash
# Set proper permissions for the installed app

APP_PATH="/Applications/brewpkg.app"

if [ -d "$APP_PATH" ]; then
    # Ensure the app is executable
    chmod -R 755 "$APP_PATH"
    
    # Make sure the main executable is executable
    if [ -f "$APP_PATH/Contents/MacOS/brewpkg" ]; then
        chmod +x "$APP_PATH/Contents/MacOS/brewpkg"
    fi
    
    # Make sure the engine script is executable
    if [ -f "$APP_PATH/Contents/Resources/brewpkg-engine.sh" ]; then
        chmod +x "$APP_PATH/Contents/Resources/brewpkg-engine.sh"
    fi
    
    echo "brewpkg installation completed successfully"
fi

exit 0
EOF

chmod +x "$SCRIPTS_DIR/postinstall"

# Create component package
COMPONENT_PKG="$TEMP_DIR/brewpkg-component.pkg"
echo "Building component package..."
pkgbuild --root "$ROOT_DIR" \
         --identifier "$BUNDLE_ID" \
         --version "$VERSION" \
         --scripts "$SCRIPTS_DIR" \
         --install-location "/" \
         "$COMPONENT_PKG"

# Check if we have an installer identity for signing
if [ -n "${APPLE_INSTALLER_IDENTITY:-}" ]; then
    echo "Signing component package with installer identity..."
    productsign --sign "$APPLE_INSTALLER_IDENTITY" \
                --timestamp \
                "$COMPONENT_PKG" \
                "$COMPONENT_PKG.signed"
    mv "$COMPONENT_PKG.signed" "$COMPONENT_PKG"
fi

# Create distribution XML
DIST_XML="$TEMP_DIR/distribution.xml"
cat > "$DIST_XML" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2.0">
    <title>brewpkg</title>
    <organization>com.ugurkoc</organization>
    <welcome file="welcome.html" mime-type="text/html"/>
    <license file="license.html" mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_localSystem="true"/>
    <installation-check script="pm_install_check();"/>
    <script>
    function pm_install_check() {
        if(system.compareVersions(system.version.ProductVersion, '15.4') &lt; 0) {
            my.result.title = "macOS 15.4 or Later Required";
            my.result.message = "brewpkg requires macOS 15.4 or later.";
            my.result.type = "Fatal";
            return false;
        }
        return true;
    }
    </script>
    <pkg-ref id="$BUNDLE_ID" version="$VERSION" onConclusion="none">brewpkg-component.pkg</pkg-ref>
    <choices-outline>
        <line choice="default">
            <line choice="$BUNDLE_ID"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$BUNDLE_ID" visible="false">
        <pkg-ref id="$BUNDLE_ID"/>
    </choice>
</installer-gui-script>
EOF

# Create welcome, license, and conclusion files
cat > "$TEMP_DIR/welcome.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; }
        h2 { color: #333; }
    </style>
</head>
<body>
    <h2>Welcome to brewpkg Installer</h2>
    <p>This installer will guide you through the installation of <strong>brewpkg</strong>, the simple and powerful macOS package builder.</p>
    <p>brewpkg allows you to:</p>
    <ul>
        <li>Create signed macOS packages with a simple drag-and-drop interface</li>
        <li>Deploy applications and files to MDM-managed devices</li>
        <li>Use pre-configured templates for common deployment scenarios</li>
    </ul>
    <p>Click <strong>Continue</strong> to proceed with the installation.</p>
</body>
</html>
EOF

cat > "$TEMP_DIR/license.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; }
        h2 { color: #333; }
    </style>
</head>
<body>
    <h2>License Agreement</h2>
    <p><strong>brewpkg</strong> is provided as-is for use in enterprise environments.</p>
    <p>By installing this software, you agree to use it in accordance with your organization's policies and applicable laws.</p>
    <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.</p>
</body>
</html>
EOF

cat > "$TEMP_DIR/conclusion.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; }
        h2 { color: #333; }
        .success { color: #28a745; }
    </style>
</head>
<body>
    <h2 class="success">Installation Successful!</h2>
    <p><strong>brewpkg</strong> has been successfully installed on your Mac.</p>
    <p>You can find the application in your Applications folder.</p>
    <p>To get started:</p>
    <ol>
        <li>Open brewpkg from your Applications folder</li>
        <li>Drag and drop an application or files to package</li>
        <li>Configure your package settings</li>
        <li>Click Build to create your package</li>
    </ol>
    <p>Visit <a href="https://intunebrew.com">IntuneBrew.com</a> for more information and tutorials.</p>
</body>
</html>
EOF

# Build distribution package
echo "Building distribution package..."
if [ -n "${APPLE_INSTALLER_IDENTITY:-}" ]; then
    echo "Creating signed distribution package..."
    productbuild --distribution "$DIST_XML" \
                 --package-path "$TEMP_DIR" \
                 --sign "$APPLE_INSTALLER_IDENTITY" \
                 --timestamp \
                 "$OUTPUT_PKG"
else
    echo "Creating unsigned distribution package..."
    productbuild --distribution "$DIST_XML" \
                 --package-path "$TEMP_DIR" \
                 "$OUTPUT_PKG"
fi

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Verify the package
echo "Verifying package..."
if [ -f "$OUTPUT_PKG" ]; then
    PKG_SIZE=$(du -h "$OUTPUT_PKG" | cut -f1)
    echo "Package created successfully: $OUTPUT_PKG (Size: $PKG_SIZE)"
    
    # Verify package signature if signed
    if [ -n "${APPLE_INSTALLER_IDENTITY:-}" ]; then
        pkgutil --check-signature "$OUTPUT_PKG" || echo "Warning: Signature verification failed"
    fi
else
    echo "Error: Package creation failed"
    exit 1
fi

echo "Package creation completed!"