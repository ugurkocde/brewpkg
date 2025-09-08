//
//  ExamplePresets.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

struct PackagePreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: PresetCategory
    let configuration: PackageConfiguration
    let hint: String
    let details: PresetDetails?
    
    enum PresetCategory: String, CaseIterable {
        case enterprise = "Enterprise"
        
        var icon: String {
            switch self {
            case .enterprise: return "building.2"
            }
        }
    }
    
    struct PresetDetails {
        let requirements: [String]
        let supportedFormats: [String]
        let notes: [String]
    }
}

class PresetManager {
    static let shared = PresetManager()
    
    let presets: [PackagePreset] = [
        // Microsoft Teams Custom Backgrounds (New Teams)
        PackagePreset(
            name: "Microsoft Teams Custom Backgrounds",
            description: "Deploy custom branded backgrounds for the new Microsoft Teams application",
            icon: "video.badge.checkmark",
            category: .enterprise,
            configuration: PackageConfiguration(
                identifier: "com.company.teams.backgrounds",
                version: "1.0.0",
                installLocation: "~/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads",
                signingIdentity: nil,
                includePreinstall: false,
                includePostinstall: true,
                preservePermissions: true,
                packageMode: .fileDeployment,
                createIntermediateFolders: true,
                preinstallScript: "#!/bin/bash\n# Pre-installation script\necho \"Preparing installation...\"\nexit 0",
                postinstallScript: """
#!/bin/bash
# Microsoft Teams Background Post-Install Script
# This script processes installed images for Teams background compatibility

echo "Processing Microsoft Teams backgrounds..."

# Get the current user
CURRENT_USER=$(whoami)

# Define the Teams backgrounds directory
TEAMS_BG_DIR="/Users/$CURRENT_USER/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"

# Create directory if it doesn't exist
if [ ! -d "$TEAMS_BG_DIR" ]; then
    echo "Creating Teams backgrounds directory..."
    mkdir -p "$TEAMS_BG_DIR"
fi

# Process each image file
for img in "$TEAMS_BG_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    if [ -f "$img" ]; then
        # Get filename without extension
        filename=$(basename "$img")
        name="${filename%.*}"
        
        # Generate a unique GUID for Teams
        GUID=$(uuidgen)
        
        # Convert to PNG if needed and rename with GUID
        if [[ "$img" =~ \\.(jpg|jpeg|JPG|JPEG)$ ]]; then
            echo "Converting $filename to PNG format..."
            sips -s format png "$img" --out "$TEAMS_BG_DIR/${GUID}.png" 2>/dev/null
            rm "$img"
        else
            # Rename PNG files with GUID
            mv "$img" "$TEAMS_BG_DIR/${GUID}.png" 2>/dev/null
        fi
        
        # Create thumbnail (Teams uses 186px height)
        if [ -f "$TEAMS_BG_DIR/${GUID}.png" ]; then
            echo "Creating thumbnail for $filename..."
            sips -Z 186 "$TEAMS_BG_DIR/${GUID}.png" --out "$TEAMS_BG_DIR/${GUID}_thumb.png" 2>/dev/null
        fi
    fi
done

echo "Microsoft Teams backgrounds installation complete!"
echo "Backgrounds will be available in Teams under Settings > Backgrounds & Effects"

exit 0
"""
            ),
            hint: "Package your company's branded backgrounds for Microsoft Teams. The postinstall script will process images and generate thumbnails automatically.",
            details: PackagePreset.PresetDetails(
                requirements: [
                    "Microsoft Teams (New) must be installed",
                    "Images should be high quality for best results",
                    "Recommended resolution: 1920x1080 or higher"
                ],
                supportedFormats: [
                    "PNG (recommended)",
                    "JPG/JPEG (will be converted to PNG)",
                    "ZIP archives containing multiple images"
                ],
                notes: [
                    "Teams automatically generates thumbnails (186px height)",
                    "Each background gets a unique GUID",
                    "Backgrounds appear immediately in Teams after installation",
                    "Users can select custom backgrounds in Teams Settings > Backgrounds & Effects"
                ]
            )
        )
    ]
    
    func presets(for category: PackagePreset.PresetCategory? = nil) -> [PackagePreset] {
        if let category = category {
            return presets.filter { $0.category == category }
        }
        return presets
    }
    
    func searchPresets(query: String) -> [PackagePreset] {
        guard !query.isEmpty else { return presets }
        
        let lowercasedQuery = query.lowercased()
        return presets.filter { preset in
            preset.name.lowercased().contains(lowercasedQuery) ||
            preset.description.lowercased().contains(lowercasedQuery) ||
            preset.hint.lowercased().contains(lowercasedQuery) ||
            preset.category.rawValue.lowercased().contains(lowercasedQuery)
        }
    }
}