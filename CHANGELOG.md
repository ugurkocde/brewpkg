# Changelog

## [1.3.0] - 2025-09-16

### Added

- **Payload-free package support** ([#11](https://github.com/ugurkocde/brewpkg/issues/11)) - Added option to build packages with only scripts (no payload files) for creating uninstall packages or script-only installers
- **Remove extended attributes option** ([#10](https://github.com/ugurkocde/brewpkg/issues/10)) - New toggle to remove extended attributes (like quarantine flags) before packaging using `xattr -cr`
- **Dynamic window title** ([#12](https://github.com/ugurkocde/brewpkg/issues/12)) - Window title now reflects the current template or app being packaged
- **Script file loading** ([#8](https://github.com/ugurkocde/brewpkg/issues/8)) - Added "Load from file" buttons for preinstall and postinstall scripts, allowing users to import existing script files
- **Binary file support** ([#16](https://github.com/ugurkocde/brewpkg/issues/16)) - Enable direct packaging of binary executables (Mach-O files) without requiring them to be zipped first
- **Enhanced file type support** ([#13](https://github.com/ugurkocde/brewpkg/issues/13)) - Drop zone now accepts individual files, scripts, and configuration files in addition to apps, DMGs, and folders

### Changed

- **Bundle identifier extraction** ([#6](https://github.com/ugurkocde/brewpkg/issues/6)) - Now uses the actual app's CFBundleIdentifier from Info.plist as the default package identifier instead of generating a generic one
- **Preserve permissions by default** ([#9](https://github.com/ugurkocde/brewpkg/issues/9)) - File permissions preservation is now enabled by default as the recommended setting
- **Product Archive creation** ([#7](https://github.com/ugurkocde/brewpkg/issues/7)) - Added `--identifier` and `--version` flags to productbuild command for proper Product Archive generation

### Fixed

- **ZIP file installation** ([#15](https://github.com/ugurkocde/brewpkg/issues/15)) - Fixed issue where ZIP archives containing apps weren't properly installing to /Applications
- **Teams Backgrounds template** ([#14](https://github.com/ugurkocde/brewpkg/issues/14)) - Fixed Microsoft Teams Backgrounds template build failures

### Technical Improvements

- Updated build engine to support `--nopayload` flag for script-only packages
- Enhanced file analysis to better handle binary files and extract bundle identifiers
- Improved package configuration validation and error handling
- Added support for removing extended attributes during the build process

### Known Issues

- DMG files containing existing PKG installers (instead of apps) need special handling - they should be run directly rather than repackaged

## [1.2.0] - 2025-08-27

### Added

- Initial public release with core packaging functionality
- Support for packaging apps from DMG, ZIP, and app bundles
- Code signing support with automatic identity detection
- Preinstall and postinstall script support
- File deployment mode for configuration files
- Template system for common package configurations
- Sparkle framework integration for automatic updates

## [1.1.0] - 2025-08-25

### Added

- Basic app packaging functionality
- Simple drag and drop interface

## [1.0.0] - 2025-08-23

### Added

- Initial development version
