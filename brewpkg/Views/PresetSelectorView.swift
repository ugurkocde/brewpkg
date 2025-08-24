//
//  PresetSelectorView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct PresetSelectorView: View {
    @Binding var configuration: PackageConfiguration
    @Binding var hasSelectedPreset: Bool
    @State private var showingPresetPicker = false
    @State private var selectedCategory: PackagePreset.PresetCategory? = nil
    @State private var searchQuery = ""
    @State private var selectedPreset: PackagePreset?
    
    private let presetManager = PresetManager.shared
    
    var filteredPresets: [PackagePreset] {
        if !searchQuery.isEmpty {
            return presetManager.searchPresets(query: searchQuery)
        } else if let category = selectedCategory {
            return presetManager.presets(for: category)
        } else {
            return presetManager.presets
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            if !hasSelectedPreset {
                Button(action: {
                    showingPresetPicker = true
                }) {
                    Label("Step 1: Select Teams Example", systemImage: "1.circle.fill")
                        .font(Typography.body())
                }
                .buttonStyle(PrimaryButtonStyle())
                .help("Start by selecting the Teams backgrounds configuration")
            } else {
                Button(action: {
                    showingPresetPicker = true
                }) {
                    Label("Teams Example", systemImage: "video.badge.checkmark")
                        .font(Typography.body())
                }
                .buttonStyle(SecondaryButtonStyle())
                .help("Change Teams configuration")
            }
            
            if let selectedPreset = selectedPreset {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.footnote)
                    Text("Using: \(selectedPreset.name)")
                        .font(Typography.caption())
                        .foregroundColor(.secondaryText)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(Color.successGreen.opacity(0.1))
                .cornerRadius(Layout.smallCornerRadius)
            }
        }
        .sheet(isPresented: $showingPresetPicker) {
            PresetPickerSheet(
                configuration: $configuration,
                selectedPreset: $selectedPreset,
                hasSelectedPreset: $hasSelectedPreset,
                isPresented: $showingPresetPicker
            )
        }
    }
}

struct PresetPickerSheet: View {
    @Binding var configuration: PackageConfiguration
    @Binding var selectedPreset: PackagePreset?
    @Binding var hasSelectedPreset: Bool
    @Binding var isPresented: Bool
    
    @State private var selectedCategory: PackagePreset.PresetCategory? = nil
    @State private var searchQuery = ""
    @State private var hoveredPreset: PackagePreset?
    
    private let presetManager = PresetManager.shared
    
    var filteredPresets: [PackagePreset] {
        if !searchQuery.isEmpty {
            return presetManager.searchPresets(query: searchQuery)
        } else if let category = selectedCategory {
            return presetManager.presets(for: category)
        } else {
            return presetManager.presets
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.warningOrange, Color.warningOrange.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Example Configuration")
                            .font(Typography.title2())
                            .foregroundColor(.primary)
                        Text("Quick setup for Microsoft Teams custom backgrounds deployment")
                            .font(Typography.footnote())
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
                
                // Search and filters
                HStack(spacing: Spacing.md) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondaryText)
                        TextField("Search presets...", text: $searchQuery)
                            .textFieldStyle(.plain)
                    }
                    .padding(Spacing.sm)
                    .background(Color.cardBackground)
                    .cornerRadius(Layout.smallCornerRadius)
                    
                }
            }
            .padding(Spacing.lg)
            .background(Color.windowBackground)
            
            Divider()
            
            // Presets grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md)
                ], spacing: Spacing.md) {
                    ForEach(filteredPresets) { preset in
                        PresetCard(
                            preset: preset,
                            isHovered: hoveredPreset?.id == preset.id,
                            onSelect: {
                                applyPreset(preset)
                            }
                        )
                        .onHover { isHovered in
                            if isHovered {
                                hoveredPreset = preset
                            } else if hoveredPreset?.id == preset.id {
                                hoveredPreset = nil
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .frame(maxHeight: 500)
            
            Divider()
            
            // Footer
            HStack {
                Text("\(filteredPresets.count) presets available")
                    .font(Typography.caption())
                    .foregroundColor(.tertiaryText)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Spacing.lg)
            .background(Color.windowBackground)
        }
        .frame(width: 800, height: 700)
        .background(Color.windowBackground)
    }
    
    private func applyPreset(_ preset: PackagePreset) {
        withAnimation(.easeInOut(duration: 0.3)) {
            configuration = preset.configuration
            selectedPreset = preset
            hasSelectedPreset = true
        }
        isPresented = false
    }
}

struct PresetCard: View {
    let preset: PackagePreset
    let isHovered: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(spacing: Spacing.sm) {
                    Image(systemName: preset.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primaryAction, Color.primaryAction.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name)
                            .font(Typography.headline())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(preset.category.rawValue)
                            .font(Typography.caption())
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                }
                
                // Description
                Text(preset.description)
                    .font(Typography.footnote())
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Configuration preview
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ConfigLine(label: "ID:", value: preset.configuration.identifier)
                    ConfigLine(label: "Version:", value: preset.configuration.version)
                    ConfigLine(label: "Location:", value: preset.configuration.installLocation)
                    
                    if preset.configuration.includePreinstall || preset.configuration.includePostinstall {
                        HStack(spacing: Spacing.xs) {
                            if preset.configuration.includePreinstall {
                                Tag(text: "preinstall", color: .warningOrange)
                            }
                            if preset.configuration.includePostinstall {
                                Tag(text: "postinstall", color: .warningOrange)
                            }
                            if preset.configuration.preservePermissions {
                                Tag(text: "permissions", color: .purple)
                            }
                        }
                    }
                }
                .padding(Spacing.sm)
                .background(Color.cardBackground.opacity(0.5))
                .cornerRadius(Layout.smallCornerRadius)
                
                // Hint
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.primaryAction)
                    Text(preset.hint)
                        .font(Typography.caption())
                        .foregroundColor(.primaryAction)
                        .lineLimit(1)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovered ? Color.primaryAction.opacity(0.05) : Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(isHovered ? Color.primaryAction.opacity(0.3) : Color.separatorColor.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Layout.cornerRadius)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(color: isHovered ? Color.primaryAction.opacity(0.1) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct ConfigLine: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption())
                .foregroundColor(.tertiaryText)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(Typography.caption())
                .foregroundColor(.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct Tag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}