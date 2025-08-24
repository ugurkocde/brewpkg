//
//  PresetDropdownView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct PresetDropdownView: View {
    @Binding var configuration: PackageConfiguration
    @Binding var hasSelectedPreset: Bool
    @Binding var inputURL: URL?
    @Binding var fileInfo: FileInfo?
    var buildEngine: BuildEngine?
    @State private var selectedPreset: PackagePreset?
    
    private let presetManager = PresetManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Template Selector
                HStack(spacing: Spacing.sm) {
                
                Menu {
                    if presetManager.presets.isEmpty {
                        Text("No templates available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(presetManager.presets) { preset in
                            Button(action: {
                                applyPreset(preset)
                            }) {
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(preset.hint)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: preset.icon)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: selectedPreset?.icon ?? "lightbulb.fill")
                            .foregroundColor(hasSelectedPreset ? .successGreen : .primaryAction)
                        
                        Text(selectedPreset?.name ?? "Use Example Template (Optional)")
                            .font(Typography.body())
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.smallCornerRadius)
                            .fill(hasSelectedPreset ? Color.successGreen.opacity(0.1) : Color.primaryAction.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.smallCornerRadius)
                            .stroke(hasSelectedPreset ? Color.successGreen.opacity(0.3) : Color.primaryAction.opacity(0.3), lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .help(hasSelectedPreset ? "Change template selection" : "Optional: Use a pre-configured template for common scenarios")
            }
            
            // Selected indicator
            if hasSelectedPreset {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.footnote)
                    Text("Using Teams Template")
                        .font(Typography.caption())
                        .foregroundColor(.successGreen)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            // Reset Button
            if hasSelectedPreset || inputURL != nil {
                Button(action: resetAll) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(Typography.body())
                }
                .buttonStyle(SecondaryButtonStyle())
                .help("Clear all settings and start over")
                .transition(.scale.combined(with: .opacity))
            }
        }
            
            // Help text for Teams template
            if hasSelectedPreset && selectedPreset != nil {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Text("This template configures the package for Microsoft Teams custom backgrounds with the correct install path and post-install script")
                        .font(Typography.caption())
                        .foregroundColor(.secondaryText)
                }
                .padding(.horizontal, Spacing.sm)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasSelectedPreset)
        .animation(.easeInOut(duration: 0.3), value: inputURL)
    }
    
    private func applyPreset(_ preset: PackagePreset) {
        withAnimation(.easeInOut(duration: 0.3)) {
            configuration = preset.configuration
            selectedPreset = preset
            hasSelectedPreset = true
        }
    }
    
    private func resetAll() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Reset configuration
            configuration = PackageConfiguration()
            
            // Reset selection states
            selectedPreset = nil
            hasSelectedPreset = false
            
            // Clear files
            inputURL = nil
            fileInfo = nil
            
            // Reset build engine
            buildEngine?.reset()
        }
    }
}

// Simplified template info display
struct TemplateInfoView: View {
    let preset: PackagePreset
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Configuration details
            GroupBox {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    InfoRow(label: "Package ID:", value: preset.configuration.identifier)
                    InfoRow(label: "Version:", value: preset.configuration.version)
                    InfoRow(label: "Install Path:", value: preset.configuration.installLocation)
                        .help(preset.configuration.installLocation)
                    
                    if preset.configuration.includePostinstall {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.caption)
                                .foregroundColor(.warningOrange)
                            Text("Includes post-install script for image processing")
                                .font(Typography.caption())
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }
            } label: {
                Label("Configuration", systemImage: "gearshape")
                    .font(Typography.footnote())
                    .foregroundColor(.secondaryText)
            }
            
            // Requirements and notes
            if let details = preset.details {
                GroupBox {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(details.requirements, id: \.self) { req in
                            HStack(alignment: .top, spacing: Spacing.xs) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                Text(req)
                                    .font(Typography.caption())
                                    .foregroundColor(.secondaryText)
                            }
                        }
                    }
                } label: {
                    Label("Requirements", systemImage: "info.circle")
                        .font(Typography.footnote())
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption())
                .foregroundColor(.tertiaryText)
                .frame(width: 80, alignment: .trailing)
            Text(value)
                .font(Typography.caption())
                .foregroundColor(.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}