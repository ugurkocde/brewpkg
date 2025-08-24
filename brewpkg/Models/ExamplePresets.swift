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
                preservePermissions: false
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