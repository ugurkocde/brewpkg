//
//  DropZoneView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct DropZoneView: View {
    @Binding var inputURL: URL?
    @Binding var fileInfo: FileInfo?
    let packageMode: PackageMode
    @State private var isDragOver = false
    @State private var animateIcon = false
    
    var dropZoneTitle: String {
        switch packageMode {
        case .application:
            return "Drop application here"
        case .fileDeployment:
            return "Drop files to deploy"
        }
    }
    
    var dropZoneSubtitle: String {
        switch packageMode {
        case .application:
            return "DMG, ZIP, App Bundle, Binary, or Directory"
        case .fileDeployment:
            return "Any Files, Folders, Scripts, or Configs"
        }
    }
    
    var dropZoneIcon: String {
        switch packageMode {
        case .application:
            return inputURL != nil ? "checkmark.seal.fill" : "arrow.down.doc.fill"
        case .fileDeployment:
            return inputURL != nil ? "checkmark.circle.fill" : "folder.badge.plus"
        }
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                // Background circle with subtle animation
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                inputURL != nil ? Color.successGreen.opacity(0.1) : Color.primaryAction.opacity(0.05),
                                inputURL != nil ? Color.successGreen.opacity(0.05) : Color.primaryAction.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
                
                // Icon
                Image(systemName: dropZoneIcon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        inputURL != nil 
                            ? LinearGradient(colors: [Color.successGreen, Color.successGreen.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.primaryAction, Color.primaryAction.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                    .rotationEffect(.degrees(isDragOver ? 5 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isDragOver)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animateIcon = true
                }
            }
            
            // Instructions
            VStack(spacing: Spacing.xs) {
                Text(inputURL != nil ? "Content Selected" : dropZoneTitle)
                    .font(Typography.headline())
                    .foregroundColor(.primary)
                
                if inputURL == nil {
                    Text(dropZoneSubtitle)
                        .font(Typography.caption())
                        .foregroundColor(.secondaryText)
                    
                    Text("or click to browse")
                        .font(Typography.footnote())
                        .foregroundColor(.tertiaryText)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(isDragOver ? Color.dropZoneHover : Color.dropZoneBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .strokeBorder(
                            style: StrokeStyle(
                                lineWidth: isDragOver ? 2 : 1.5,
                                dash: isDragOver ? [] : [10, 5]
                            )
                        )
                        .foregroundColor(
                            isDragOver ? Color.primaryAction : 
                            (inputURL != nil ? Color.successGreen.opacity(0.5) : Color.separatorColor)
                        )
                )
        )
        .scaleEffect(isDragOver ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
        .shadow(
            color: isDragOver ? Color.primaryAction.opacity(0.15) : Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .onTapGesture {
            selectFile()
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Choose Input for Package"
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "dmg") ?? .data,
            UTType(filenameExtension: "zip") ?? .archive,
            UTType(filenameExtension: "app") ?? .applicationBundle,
            .folder,
            .executable,
            .unixExecutable,
            .item  // Allow any file type
        ]
        
        if panel.runModal() == .OK {
            inputURL = panel.url
            if let url = panel.url {
                fileInfo = FileHelper.analyzeFile(at: url)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard error == nil,
                  let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                if isValidInput(url) {
                    self.inputURL = url
                    self.fileInfo = FileHelper.analyzeFile(at: url)
                }
            }
        }
        
        return true
    }
    
    private func isValidInput(_ url: URL) -> Bool {
        let validExtensions = ["dmg", "zip", "app"]
        
        // Allow directories
        if url.hasDirectoryPath {
            return true
        }
        
        // Allow files with valid extensions
        if validExtensions.contains(url.pathExtension.lowercased()) {
            return true
        }
        
        // Allow executable files (binaries)
        let fileManager = FileManager.default
        if fileManager.isExecutableFile(atPath: url.path) {
            return true
        }
        
        // In file deployment mode, allow any file
        if packageMode == .fileDeployment {
            return true
        }
        
        return false
    }
}

