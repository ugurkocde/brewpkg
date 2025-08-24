#!/bin/bash

set -euo pipefail

readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Default values
IDENTIFIER=""
VERSION_STRING="1.0"
INSTALL_LOCATION="/Applications"
INPUT_PATH=""
OUTPUT_PATH=""
SIGN_IDENTITY=""
INCLUDE_PREINSTALL=false
INCLUDE_POSTINSTALL=false
PRESERVE_PERMISSIONS=false
VERBOSE=false
FILE_DEPLOYMENT_MODE=false
CREATE_INTERMEDIATE_FOLDERS=false

# Temporary directories
WORK_DIR=""
MOUNT_POINT=""
EXPANDED_DIR=""
SCRIPTS_DIR=""
ROOT_DIR=""

# Cleanup function
cleanup() {
    local exit_code=$?
    
    if [[ -n "$MOUNT_POINT" ]] && [[ -d "$MOUNT_POINT" ]]; then
        echo "Unmounting DMG..."
        hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    fi
    
    if [[ -n "$WORK_DIR" ]] && [[ -d "$WORK_DIR" ]]; then
        echo "Cleaning up temporary files..."
        rm -rf "$WORK_DIR"
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM

# Usage function
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -i, --identifier ID          Package identifier (required)
    -v, --version VERSION        Package version (default: 1.0)
    -l, --location PATH          Install location (default: /Applications)
    -p, --input PATH            Input file/directory (required)
    -o, --output PATH           Output package path (required)
    -s, --sign IDENTITY        Signing identity
    --preinstall                Include preinstall script
    --postinstall               Include postinstall script
    --preserve-permissions      Preserve file permissions
    --verbose                   Verbose output
    -h, --help                  Show this help message

Examples:
    $SCRIPT_NAME -i com.example.app -p MyApp.dmg -o MyApp.pkg
    $SCRIPT_NAME -i com.example.tool -v 2.0 -l /usr/local/bin -p tool.zip -o tool.pkg
EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--identifier)
                IDENTIFIER="$2"
                shift 2
                ;;
            -v|--version)
                VERSION_STRING="$2"
                shift 2
                ;;
            -l|--location)
                INSTALL_LOCATION="$2"
                shift 2
                ;;
            -p|--input)
                INPUT_PATH="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_PATH="$2"
                shift 2
                ;;
            -s|--sign)
                SIGN_IDENTITY="$2"
                shift 2
                ;;
            --preinstall)
                INCLUDE_PREINSTALL=true
                shift
                ;;
            --postinstall)
                INCLUDE_POSTINSTALL=true
                shift
                ;;
            --preserve-permissions)
                PRESERVE_PERMISSIONS=true
                shift
                ;;
            --file-deployment-mode)
                FILE_DEPLOYMENT_MODE=true
                shift
                ;;
            --create-intermediate-folders)
                CREATE_INTERMEDIATE_FOLDERS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Error: Unknown option $1" >&2
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$IDENTIFIER" ]]; then
        echo "Error: Package identifier is required" >&2
        exit 1
    fi
    
    if [[ -z "$INPUT_PATH" ]]; then
        echo "Error: Input path is required" >&2
        exit 1
    fi
    
    if [[ -z "$OUTPUT_PATH" ]]; then
        echo "Error: Output path is required" >&2
        exit 1
    fi
    
    if [[ ! -e "$INPUT_PATH" ]]; then
        echo "Error: Input path does not exist: $INPUT_PATH" >&2
        exit 1
    fi
}

# Log function
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    else
        echo "$*"
    fi
}

# Detect architecture and set appropriate bin path
detect_bin_path() {
    local arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "/opt/homebrew/bin"
    else
        echo "/usr/local/bin"
    fi
}

# Mount DMG
mount_dmg() {
    local dmg_path="$1"
    log "Mounting DMG: $dmg_path"
    
    local mount_output
    mount_output=$(hdiutil attach "$dmg_path" -nobrowse -readonly -noverify -noautoopen 2>&1)
    
    MOUNT_POINT=$(echo "$mount_output" | grep -E "^/Volumes/" | tail -1 | awk '{print $1}')
    
    if [[ -z "$MOUNT_POINT" ]]; then
        echo "Error: Failed to mount DMG" >&2
        exit 1
    fi
    
    log "DMG mounted at: $MOUNT_POINT"
}

# Extract ZIP
extract_zip() {
    local zip_path="$1"
    local dest_dir="$2"
    
    log "Extracting ZIP: $zip_path"
    
    mkdir -p "$dest_dir"
    
    if [[ "$PRESERVE_PERMISSIONS" == true ]]; then
        ditto -x -k "$zip_path" "$dest_dir"
    else
        unzip -q "$zip_path" -d "$dest_dir"
    fi
    
    log "ZIP extracted to: $dest_dir"
}

# Copy directory or app
copy_content() {
    local src="$1"
    local dest="$2"
    
    log "Copying content from: $src to: $dest"
    
    mkdir -p "$dest"
    
    if [[ "$PRESERVE_PERMISSIONS" == true ]]; then
        ditto "$src" "$dest"
    else
        cp -R "$src"/* "$dest/" 2>/dev/null || cp -R "$src" "$dest/"
    fi
}

# Detect if content is an app bundle
is_app_bundle() {
    local path="$1"
    
    if [[ -d "$path" ]] && [[ "${path##*.}" == "app" ]]; then
        return 0
    fi
    
    # Check if directory contains a single .app
    local app_count=$(find "$path" -maxdepth 1 -name "*.app" -type d | wc -l)
    if [[ $app_count -eq 1 ]]; then
        return 0
    fi
    
    return 1
}

# Find app bundle in directory
find_app_bundle() {
    local dir="$1"
    find "$dir" -maxdepth 1 -name "*.app" -type d | head -1
}

# Create preinstall script
create_preinstall_script() {
    cat > "$1" <<'EOF'
#!/bin/bash
# Preinstall script
echo "Preparing to install package..."
exit 0
EOF
    chmod 755 "$1"
}

# Create postinstall script
create_postinstall_script() {
    if [[ "$FILE_DEPLOYMENT_MODE" == true ]] && [[ "$CREATE_INTERMEDIATE_FOLDERS" == true ]]; then
        cat > "$1" <<EOF
#!/bin/bash
# Postinstall script for file deployment

# Create intermediate directories if they don't exist
TARGET_DIR="$INSTALL_LOCATION"
if [[ ! -d "\$TARGET_DIR" ]]; then
    echo "Creating directory: \$TARGET_DIR"
    mkdir -p "\$TARGET_DIR"
    
    # Set appropriate permissions
    chmod 755 "\$TARGET_DIR"
fi

echo "File deployment completed to \$TARGET_DIR"
exit 0
EOF
    else
        cat > "$1" <<'EOF'
#!/bin/bash
# Postinstall script
echo "Package installation completed."
exit 0
EOF
    fi
    chmod 755 "$1"
}

# Expand input to working directory
expand_input() {
    log "Expanding input: $INPUT_PATH"
    
    EXPANDED_DIR="$WORK_DIR/expanded"
    mkdir -p "$EXPANDED_DIR"
    
    local input_type=""
    
    if [[ -f "$INPUT_PATH" ]]; then
        local extension="${INPUT_PATH##*.}"
        case "$extension" in
            dmg|DMG)
                input_type="dmg"
                mount_dmg "$INPUT_PATH"
                copy_content "$MOUNT_POINT" "$EXPANDED_DIR"
                ;;
            zip|ZIP)
                input_type="zip"
                extract_zip "$INPUT_PATH" "$EXPANDED_DIR"
                ;;
            *)
                echo "Error: Unsupported file type: $extension" >&2
                exit 1
                ;;
        esac
    elif [[ -d "$INPUT_PATH" ]]; then
        input_type="directory"
        copy_content "$INPUT_PATH" "$EXPANDED_DIR"
    else
        echo "Error: Invalid input path: $INPUT_PATH" >&2
        exit 1
    fi
    
    log "Input expanded successfully (type: $input_type)"
}

# Prepare package root
prepare_package_root() {
    log "Preparing package root"
    
    ROOT_DIR="$WORK_DIR/root"
    local install_dir="$ROOT_DIR$INSTALL_LOCATION"
    mkdir -p "$install_dir"
    
    # If in file deployment mode, just copy everything as-is
    if [[ "$FILE_DEPLOYMENT_MODE" == true ]]; then
        log "File deployment mode: copying content directly to $INSTALL_LOCATION"
        copy_content "$EXPANDED_DIR" "$install_dir"
    # Check if we have an app bundle
    elif is_app_bundle "$EXPANDED_DIR"; then
        local app_path=""
        if [[ "${EXPANDED_DIR##*.}" == "app" ]]; then
            app_path="$EXPANDED_DIR"
        else
            app_path=$(find_app_bundle "$EXPANDED_DIR")
        fi
        
        if [[ -n "$app_path" ]]; then
            log "Found app bundle: $(basename "$app_path")"
            copy_content "$app_path" "$install_dir/$(basename "$app_path")"
        fi
    else
        # Check if this looks like CLI tools
        local has_executables=false
        if find "$EXPANDED_DIR" -type f -perm +111 | grep -q .; then
            has_executables=true
        fi
        
        if [[ "$has_executables" == true ]] && [[ "$INSTALL_LOCATION" == "/Applications" ]]; then
            # Likely CLI tools, use appropriate bin directory
            local bin_path=$(detect_bin_path)
            log "Detected CLI tools, using bin path: $bin_path"
            INSTALL_LOCATION="$bin_path"
            install_dir="$ROOT_DIR$INSTALL_LOCATION"
            mkdir -p "$install_dir"
        fi
        
        # Copy all content
        copy_content "$EXPANDED_DIR" "$install_dir"
    fi
    
    log "Package root prepared at: $ROOT_DIR"
}

# Create scripts
create_scripts() {
    if [[ "$INCLUDE_PREINSTALL" == true ]] || [[ "$INCLUDE_POSTINSTALL" == true ]]; then
        SCRIPTS_DIR="$WORK_DIR/scripts"
        mkdir -p "$SCRIPTS_DIR"
        
        if [[ "$INCLUDE_PREINSTALL" == true ]]; then
            log "Creating preinstall script"
            create_preinstall_script "$SCRIPTS_DIR/preinstall"
        fi
        
        if [[ "$INCLUDE_POSTINSTALL" == true ]]; then
            log "Creating postinstall script"
            create_postinstall_script "$SCRIPTS_DIR/postinstall"
        fi
    fi
}

# Build package
build_package() {
    log "Building package"
    
    local component_pkg="$WORK_DIR/component.pkg"
    
    # Build component package with pkgbuild
    local pkgbuild_args=(
        --root "$ROOT_DIR"
        --identifier "$IDENTIFIER"
        --version "$VERSION_STRING"
        --install-location "/"
    )
    
    if [[ -n "$SCRIPTS_DIR" ]]; then
        pkgbuild_args+=(--scripts "$SCRIPTS_DIR")
    fi
    
    if [[ "$PRESERVE_PERMISSIONS" == true ]]; then
        pkgbuild_args+=(--preserve-xattr)
    fi
    
    log "Running pkgbuild..."
    pkgbuild "${pkgbuild_args[@]}" "$component_pkg"
    
    # Build distribution package with productbuild
    local productbuild_args=(
        --package "$component_pkg"
    )
    
    if [[ -n "$SIGN_IDENTITY" ]]; then
        log "Signing package with identity: $SIGN_IDENTITY"
        productbuild_args+=(--sign "$SIGN_IDENTITY")
    fi
    
    productbuild_args+=("$OUTPUT_PATH")
    
    log "Running productbuild..."
    productbuild "${productbuild_args[@]}"
    
    log "Package created successfully: $OUTPUT_PATH"
}

# Main function
main() {
    parse_args "$@"
    
    # Create working directory
    WORK_DIR=$(mktemp -d -t brewpkg)
    log "Working directory: $WORK_DIR"
    
    # Expand input
    expand_input
    
    # Prepare package root
    prepare_package_root
    
    # Create scripts if needed
    create_scripts
    
    # Build the package
    build_package
    
    log "Build completed successfully!"
}

# Run main function
main "$@"