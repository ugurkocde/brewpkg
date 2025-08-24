#!/bin/bash

# Generate appcast.xml for Sparkle updates
# This script generates an appcast feed from the releases directory

set -e

# Configuration
RELEASES_DIR="releases"
APPCAST_FILE="$RELEASES_DIR/appcast.xml"
BASE_URL="https://github.com/ugurkocde/brewpkg/releases/download"
RAW_URL="https://raw.githubusercontent.com/ugurkocde/brewpkg/main/releases"

# Check if releases directory exists
if [ ! -d "$RELEASES_DIR" ]; then
    echo "Releases directory not found. Creating it..."
    mkdir -p "$RELEASES_DIR"
fi

# Function to extract version from pkg file
extract_version() {
    local pkg_file=$1
    # Try to get version from GitHub Actions environment or Info.plist
    if [ -n "$VERSION" ]; then
        echo "$VERSION"
    elif [ -f "brewpkg/Info.plist" ]; then
        /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" brewpkg/Info.plist 2>/dev/null || echo "1.0.0"
    else
        echo "1.0.0"
    fi
}

# Function to get file size
get_file_size() {
    local file=$1
    stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
}

# Function to calculate EdDSA signature
calculate_signature() {
    local file=$1
    
    # Check for private key in environment (GitHub Actions) or local file
    if [ -n "$SPARKLE_PRIVATE_KEY" ]; then
        # Use private key from environment variable
        PRIVATE_KEY="$SPARKLE_PRIVATE_KEY"
    elif [ -f "sparkle_private.key" ]; then
        # Use local private key file (for local testing only)
        PRIVATE_KEY=$(cat sparkle_private.key)
    else
        echo "WARNING: No private key found. Using placeholder signature." >&2
        echo "MEUCIQDQkPgkr1XnbmLmP8vYPgKGbqcLv2p5K5vqw3I7HqMbPwIgZGlzIGlzIGEgcGxhY2Vob2xkZXIgc2lnbmF0dXJl"
        return
    fi
    
    # Try to find or download sign_update tool
    SIGN_UPDATE=""
    if [ -f "./sign_update" ]; then
        SIGN_UPDATE="./sign_update"
    elif [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -path "*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" -type f 2>/dev/null | head -1)
    fi
    
    # If not found and we're in CI, download Sparkle
    if [ -z "$SIGN_UPDATE" ] && [ -n "$CI" ]; then
        echo "Downloading Sparkle tools for signing..." >&2
        SPARKLE_VERSION="2.6.4"
        curl -L -o sparkle.tar.xz "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"
        tar -xf sparkle.tar.xz
        if [ -f "bin/sign_update" ]; then
            SIGN_UPDATE="./bin/sign_update"
            chmod +x "$SIGN_UPDATE"
        fi
        rm -f sparkle.tar.xz
    fi
    
    if [ -n "$SIGN_UPDATE" ] && [ -f "$SIGN_UPDATE" ]; then
        # Write private key to temporary file for signing
        TEMP_KEY_FILE=$(mktemp)
        echo "$PRIVATE_KEY" > "$TEMP_KEY_FILE"
        
        # Sign the file with Sparkle's sign_update tool using -f flag
        FULL_OUTPUT=$("$SIGN_UPDATE" "$file" -f "$TEMP_KEY_FILE" 2>/dev/null | tail -1)
        
        # Clean up temp file
        rm -f "$TEMP_KEY_FILE"
        
        # Extract just the signature value from the output
        # The output format is: sparkle:edSignature="SIGNATURE" length="SIZE"
        # We need just the SIGNATURE part
        if [[ "$FULL_OUTPUT" =~ sparkle:edSignature=\"([^\"]+)\" ]]; then
            SIGNATURE="${BASH_REMATCH[1]}"
            echo "$SIGNATURE"
        elif [ -n "$FULL_OUTPUT" ] && [ "$FULL_OUTPUT" != *"ERROR"* ]; then
            # Fallback: if it's just the signature without the format
            echo "$FULL_OUTPUT"
        else
            echo "WARNING: Signing failed. Using placeholder signature." >&2
            echo "MEUCIQDQkPgkr1XnbmLmP8vYPgKGbqcLv2p5K5vqw3I7HqMbPwIgZGlzIGlzIGEgcGxhY2Vob2xkZXIgc2lnbmF0dXJl"
        fi
    else
        echo "WARNING: sign_update tool not found. Using placeholder signature." >&2
        echo "MEUCIQDQkPgkr1XnbmLmP8vYPgKGbqcLv2p5K5vqw3I7HqMbPwIgZGlzIGlzIGEgcGxhY2Vob2xkZXIgc2lnbmF0dXJl"
    fi
}

# Start generating appcast XML
cat > "$APPCAST_FILE" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>brewpkg Updates</title>
    <link>https://raw.githubusercontent.com/ugurkocde/brewpkg/main/releases/appcast.xml</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
EOF

# Check if brewpkg.pkg exists
if [ -f "$RELEASES_DIR/brewpkg.pkg" ]; then
    PKG_FILE="$RELEASES_DIR/brewpkg.pkg"
    VERSION=$(extract_version "$PKG_FILE")
    FILE_SIZE=$(get_file_size "$PKG_FILE")
    SIGNATURE=$(calculate_signature "$PKG_FILE")
    
    # Get current date in RFC 2822 format
    PUB_DATE=$(date -R 2>/dev/null || date "+%a, %d %b %Y %H:%M:%S %z")
    
    # Add item to appcast
    cat >> "$APPCAST_FILE" << EOF
    <item>
      <title>Version $VERSION</title>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <link>$RAW_URL/brewpkg.pkg</link>
      <sparkle:edSignature>$SIGNATURE</sparkle:edSignature>
      <pubDate>$PUB_DATE</pubDate>
      <enclosure 
        url="$RAW_URL/brewpkg.pkg"
        sparkle:version="$VERSION"
        sparkle:shortVersionString="$VERSION"
        length="$FILE_SIZE"
        type="application/octet-stream"
        sparkle:edSignature="$SIGNATURE"
      />
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
    </item>
EOF
fi

# Close the RSS feed
cat >> "$APPCAST_FILE" << 'EOF'
  </channel>
</rss>
EOF

echo "Appcast generated at $APPCAST_FILE"

# Check if signature was properly generated
if [ -z "$SPARKLE_PRIVATE_KEY" ] && [ ! -f "sparkle_private.key" ]; then
    echo ""
    echo "⚠️  WARNING: No signing key available!"
    echo "For production releases, add SPARKLE_PRIVATE_KEY to GitHub Secrets"
    echo "For local testing, you can temporarily use: export SPARKLE_PRIVATE_KEY='your-key-here'"
fi