//
//  ContentView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Sparkle

struct ContentView: View {
    let updaterController: SPUStandardUpdaterController
    @State private var inputURL: URL?
    @State private var fileInfo: FileInfo?
    @State private var configuration = PackageConfiguration()
    @StateObject private var buildEngine = BuildEngine()
    @State private var showingSavePanel = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var outputPackageURL: URL?
    @State private var isValidIdentifier = true
    @State private var selectedTemplate: PackageTemplate?
    @StateObject private var signingIdentityManager = SigningIdentityManager()
    @State private var customInstallLocation = false
    @State private var showLogExpanded = false
    @State private var buildStatus: BuildStatusInfo?
    @State private var packageInfoExpanded = true
    @State private var codeSigningExpanded = true
    @State private var buildOptionsExpanded = true
    @State private var isCheckingForUpdates = false
    @State private var updateCheckMessage = ""
    
    init(updaterController: SPUStandardUpdaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)) {
        self.updaterController = updaterController
    }
    
    var canBuild: Bool {
        if case .building = buildEngine.state {
            return false
        }
        return inputURL != nil && configuration.isValid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Banner
            if let status = buildStatus {
                StatusBannerView(status: status, outputURL: outputPackageURL)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main Content
            HStack(spacing: 0) {
                // Left Column - Drop Zone
                VStack(spacing: Spacing.lg) {
                    HeaderView()
                        .padding(.top, Spacing.lg)
                    
                    DropZoneView(
                        inputURL: $inputURL, 
                        fileInfo: $fileInfo,
                        packageMode: configuration.packageMode
                    )
                    .onChange(of: fileInfo) { info in
                        if let info = info {
                            autofillConfiguration(from: info)
                        }
                    }
                    
                    // File Preview
                    if let fileInfo = fileInfo {
                        FilePreviewCard(fileInfo: fileInfo)
                    }
                    
                    Spacer()
                    
                    // Version & Updates
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                                    .font(Typography.caption())
                                    .foregroundColor(.secondaryText)
                                
                                if isCheckingForUpdates {
                                    HStack(spacing: 4) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 12, height: 12)
                                        Text("Checking for updates...")
                                            .font(Typography.caption())
                                            .foregroundColor(.secondaryText)
                                    }
                                } else if !updateCheckMessage.isEmpty {
                                    Text(updateCheckMessage)
                                        .font(Typography.caption())
                                        .foregroundColor(.secondaryText)
                                        .transition(.opacity)
                                } else {
                                    Button(action: {
                                        checkForUpdates()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.triangle.2.circlepath.circle")
                                                .font(.caption)
                                            Text("Check for Updates")
                                                .font(Typography.caption())
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.primaryAction)
                                    .onHover { isHovering in
                                        if isHovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, Spacing.sm)
                    }
                    
                    // Branding & Ecosystem
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Divider()
                            .padding(.bottom, Spacing.xs)
                        
                        // IntuneBrew Link
                        Button(action: {
                            if let url = URL(string: "https://intunebrew.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "globe")
                                    .font(.footnote)
                                Text("Discover more at IntuneBrew.com")
                                    .font(Typography.footnote())
                            }
                            .foregroundColor(.primaryAction)
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            if isHovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .help("Visit IntuneBrew for macOS app management in Intune")
                        
                        Text("Includes patch management for macOS apps in Intune")
                            .font(Typography.caption())
                            .foregroundColor(.tertiaryText)
                            .lineLimit(2)
                        
                        // Author credits
                        HStack(spacing: Spacing.xs) {
                            // Made by Ugur with LinkedIn
                            Button(action: {
                                if let url = URL(string: "https://www.linkedin.com/in/ugurkocde/") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Made by Ugur")
                                        .font(Typography.footnote())
                                        .foregroundColor(.secondaryText)
                                    
                                    // LinkedIn Logo
                                    Text("in")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color(red: 0.0, green: 119.0/255.0, blue: 181.0/255.0))
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovering in
                                if isHovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .help("Connect with Ugur on LinkedIn")
                            
                            Text("and the")
                                .font(Typography.footnote())
                                .foregroundColor(.tertiaryText)
                            
                            // Intune Community Heroes link
                            Button(action: {
                                if let url = URL(string: "https://www.linkedin.com/groups/14802021") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Intune Community Heroes")
                                        .font(Typography.footnote())
                                        .foregroundColor(.secondaryText)
                                    
                                    // LinkedIn Logo
                                    Text("in")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color(red: 0.0, green: 119.0/255.0, blue: 181.0/255.0))
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovering in
                                if isHovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .help("Join the Intune Community Heroes group on LinkedIn")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 360)
                .padding(Spacing.lg)
                .background(Color.windowBackground)
                
                Divider()
                
                // Right Column - Configuration
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Package Mode Selector
                        PackageModeSelector(packageMode: $configuration.packageMode)
                            .padding(.top, Spacing.lg)
                        
                        // Template Selector
                        TemplateSelector(
                            selectedTemplate: $selectedTemplate,
                            configuration: $configuration
                        )
                        
                        // Package Information
                        ConfigurationSection(title: "Package Information", icon: "shippingbox.fill", isExpanded: $packageInfoExpanded) {
                            VStack(spacing: Spacing.md) {
                                ConfigField(
                                    label: "Identifier",
                                    isRequired: true,
                                    validation: configuration.identifier.isEmpty || configuration.identifier.contains(".")
                                ) {
                                    TextField("com.company.app", text: $configuration.identifier)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                ConfigField(label: "Version", isRequired: true) {
                                    TextField("1.0.0", text: $configuration.version)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 120)
                                }
                                
                                ConfigField(
                                    label: configuration.packageMode == .fileDeployment ? "Deploy to Path" : "Install Location",
                                    isRequired: true
                                ) {
                                    InstallLocationPicker(
                                        installLocation: $configuration.installLocation,
                                        customInstallLocation: $customInstallLocation,
                                        packageMode: configuration.packageMode
                                    )
                                }
                            }
                        }
                        
                        // Code Signing
                        ConfigurationSection(title: "Code Signing", icon: "checkmark.seal.fill", isExpanded: $codeSigningExpanded) {
                            SigningIdentityPicker(
                                signingIdentity: $configuration.signingIdentity,
                                manager: signingIdentityManager
                            )
                        }
                        
                        // Build Options
                        ConfigurationSection(title: "Build Options", icon: "gearshape.2.fill", isExpanded: $buildOptionsExpanded) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Toggle("Include preinstall script", isOn: $configuration.includePreinstall)
                                Toggle("Include postinstall script", isOn: $configuration.includePostinstall)
                                Toggle("Preserve file permissions", isOn: $configuration.preservePermissions)
                                
                                if configuration.packageMode == .fileDeployment {
                                    Divider()
                                        .padding(.vertical, Spacing.xs)
                                    
                                    Toggle("Create intermediate folders if needed", isOn: $configuration.createIntermediateFolders)
                                        .help("Automatically create parent directories if they don't exist")
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                        
                        // Build Controls
                        HStack(spacing: Spacing.md) {
                            if case .building = buildEngine.state {
                                ProgressView()
                                    .progressViewStyle(.linear)
                                    .frame(maxWidth: 200)
                                
                                Text("\(Int(buildEngine.progress * 100))%")
                                    .font(Typography.caption())
                                    .foregroundColor(.secondaryText)
                                
                                Button("Cancel") {
                                    buildEngine.cancel()
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button("Build Package") {
                                    buildPackage()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .disabled(!canBuild)
                                .keyboardShortcut(.return, modifiers: .command)
                            }
                        }
                        .padding(.vertical, Spacing.md)
                        
                        // Build Log
                        ConfigurationSection(
                            title: "Build Log",
                            icon: "terminal.fill",
                            isExpanded: $showLogExpanded
                        ) {
                            BuildLogView(
                                logOutput: buildEngine.logOutput,
                                isExpanded: showLogExpanded
                            )
                        }
                        
                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        .background(Color.windowBackground)
        .alert("Build Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            signingIdentityManager.loadIdentities()
        }
        .onChange(of: buildEngine.state) { newState in
            updateBuildStatus(newState)
        }
    }
    
    private func autofillConfiguration(from fileInfo: FileInfo) {
        if configuration.identifier.isEmpty {
            configuration.identifier = fileInfo.suggestedIdentifier
        }
        if let version = fileInfo.version, configuration.version == "1.0" {
            configuration.version = version
        }
    }
    
    private func updateBuildStatus(_ state: BuildState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch state {
            case .completed:
                buildStatus = BuildStatusInfo(
                    type: .success,
                    message: "Package built successfully",
                    detail: outputPackageURL?.lastPathComponent
                )
            case .failed(let error):
                buildStatus = BuildStatusInfo(
                    type: .error,
                    message: "Build failed",
                    detail: error.localizedDescription
                )
                showLogExpanded = true
            case .idle, .building:
                buildStatus = nil
            }
        }
    }
    
    private func buildPackage() {
        guard let inputURL = inputURL else { return }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save Package As"
        savePanel.allowedContentTypes = [UTType(filenameExtension: "pkg") ?? .data]
        savePanel.nameFieldStringValue = "\(inputURL.deletingPathExtension().lastPathComponent).pkg"
        savePanel.canCreateDirectories = true
        
        if savePanel.runModal() == .OK, let outputURL = savePanel.url {
            Task {
                do {
                    try await buildEngine.build(
                        configuration: configuration,
                        inputURL: inputURL,
                        outputURL: outputURL
                    )
                    
                    await MainActor.run {
                        self.outputPackageURL = outputURL
                    }
                } catch {
                    await MainActor.run {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    private func resetAll() {
        // Clear all state
        inputURL = nil
        fileInfo = nil
        configuration = PackageConfiguration()
        selectedTemplate = nil
        outputPackageURL = nil
        buildStatus = nil
        buildEngine.reset()
        showLogExpanded = false
    }
    
    private func checkForUpdates() {
        isCheckingForUpdates = true
        updateCheckMessage = ""
        
        // Trigger Sparkle update check directly through the updater
        updaterController.updater.checkForUpdates()
        
        // Show checking status briefly, Sparkle will handle the rest
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingForUpdates = false
            // Don't show "up to date" message - let Sparkle handle all feedback
            updateCheckMessage = ""
        }
    }
}

// Status Banner
struct StatusBannerView: View {
    let status: BuildStatusInfo
    let outputURL: URL?
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            Image(systemName: status.type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status.type == .success ? .successGreen : .errorRed)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(status.message)
                    .font(Typography.body().weight(.medium))
                if let detail = status.detail {
                    Text(detail)
                        .font(Typography.caption())
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            if status.type == .success, let url = outputURL {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(Spacing.md)
        .background(status.type == .success ? Color.successGreen.opacity(0.1) : Color.errorRed.opacity(0.1))
        .overlay(
            Rectangle()
                .fill(status.type == .success ? Color.successGreen : Color.errorRed)
                .frame(height: 2),
            alignment: .bottom
        )
    }
}

// File Preview Card
struct FilePreviewCard: View {
    let fileInfo: FileInfo
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                // Show app icon if available, otherwise system icon
                Group {
                    if let appIcon = fileInfo.appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: fileInfo.type.icon)
                            .font(.system(size: 32))
                            .foregroundColor(.primaryAction)
                            .frame(width: 48, height: 48)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileInfo.url.lastPathComponent)
                        .font(Typography.body().weight(.medium))
                        .lineLimit(1)
                    
                    HStack(spacing: Spacing.sm) {
                        Label(fileInfo.formattedSize, systemImage: "doc.text")
                        if let appName = fileInfo.appName {
                            Label(appName, systemImage: "app.badge")
                        }
                        if let version = fileInfo.version {
                            Label("v\(version)", systemImage: "number")
                        }
                    }
                    .font(Typography.caption())
                    .foregroundColor(.secondaryText)
                }
                
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(Layout.cornerRadius)
        }
    }
}

// Configuration Section
struct ConfigurationSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: () -> Content
    
    init(title: String, icon: String, isExpanded: Binding<Bool> = .constant(true), @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.primaryAction)
                    Text(title)
                        .font(Typography.headline())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content()
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cornerRadius)
    }
}

// Config Field
struct ConfigField<Content: View>: View {
    let label: String
    let isRequired: Bool
    let validation: Bool
    let content: () -> Content
    
    init(label: String, isRequired: Bool = false, validation: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.isRequired = isRequired
        self.validation = validation
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            HStack(spacing: 4) {
                Text(label)
                if isRequired {
                    Text("*")
                        .foregroundColor(.errorRed)
                }
            }
            .font(Typography.body())
            .frame(width: 120, alignment: .trailing)
            
            content()
                .overlay(
                    Group {
                        if !validation {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.errorRed, lineWidth: 1)
                        }
                    }
                )
            
            Spacer()
        }
    }
}

// Install Location Picker
struct InstallLocationPicker: View {
    @Binding var installLocation: String
    @Binding var customInstallLocation: Bool
    let packageMode: PackageMode
    
    var commonLocations: [(String, String, String)] {
        if packageMode == .fileDeployment {
            return [
                ("Application Support", "/Library/Application Support", "folder.fill"),
                ("Company Folder", "/Library/Application Support/YourCompany", "building.2.fill"),
                ("Shared Folder", "/Users/Shared", "person.2.fill"),
                ("Preferences", "/Library/Preferences", "gearshape.fill"),
                ("Launch Daemons", "/Library/LaunchDaemons", "gear.badge"),
                ("Launch Agents", "/Library/LaunchAgents", "person.crop.circle.badge.clock"),
                ("Scripts", "/usr/local/YourCompany", "terminal.fill"),
                ("Custom...", "custom", "pencil")
            ]
        } else {
            return [
                ("Applications", "/Applications", "app.fill"),
                ("Utilities", "/Applications/Utilities", "wrench.and.screwdriver.fill"),
                ("User Binaries", "/usr/local/bin", "terminal.fill"),
                ("Homebrew (Intel)", "/usr/local/bin", "cup.and.saucer.fill"),
                ("Homebrew (AS)", "/opt/homebrew/bin", "cpu"),
                ("Library Support", "/Library/Application Support", "folder.fill"),
                ("Preferences", "/Library/PreferencePanes", "gearshape.fill"),
                ("Custom...", "custom", "pencil")
            ]
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if customInstallLocation {
                TextField("Enter custom path", text: $installLocation)
                    .textFieldStyle(.roundedBorder)
                
                Button("Presets") {
                    customInstallLocation = false
                    installLocation = "/Applications"
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Menu {
                    ForEach(commonLocations, id: \.1) { name, path, icon in
                        Button(action: {
                            if path == "custom" {
                                customInstallLocation = true
                            } else {
                                installLocation = path
                            }
                        }) {
                            Label(name, systemImage: icon)
                        }
                    }
                } label: {
                    HStack {
                        Text(commonLocations.first(where: { $0.1 == installLocation })?.0 ?? installLocation)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.cardBackground)
                    .cornerRadius(6)
                }
                .frame(maxWidth: 300)
            }
        }
    }
}

// Signing Identity Picker
struct SigningIdentityPicker: View {
    @Binding var signingIdentity: String?
    let manager: SigningIdentityManager
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Picker("", selection: $signingIdentity) {
                Text("None (Unsigned)")
                    .tag(String?.none)
                
                if !manager.identities.isEmpty {
                    Divider()
                    ForEach(manager.identities) { identity in
                        Text(identity.displayName)
                            .tag(String?.some(identity.name))
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 400)
            
            Button(action: { manager.loadIdentities() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh signing identities")
        }
    }
}

// Build Log View
struct BuildLogView: View {
    let logOutput: String
    let isExpanded: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(logOutput.isEmpty ? "Build output will appear here..." : logOutput)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(logOutput.isEmpty ? .tertiaryText : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.sm)
                    .textSelection(.enabled)
                    .id("logBottom")
            }
            .frame(height: isExpanded ? 300 : 150)
            .background(Color.black.opacity(0.05))
            .cornerRadius(Layout.smallCornerRadius)
            .onChange(of: logOutput) { _ in
                withAnimation {
                    proxy.scrollTo("logBottom", anchor: .bottom)
                }
            }
        }
    }
}

// Template Selector
struct TemplateSelector: View {
    @Binding var selectedTemplate: PackageTemplate?
    @Binding var configuration: PackageConfiguration
    @StateObject private var templateManager = TemplateManager()
    @State private var showingSaveDialog = false
    @State private var newTemplateName = ""
    @State private var originalConfiguration: PackageConfiguration?
    
    private let defaultTemplates = [
        PackageTemplate(
            name: "Microsoft Teams Backgrounds",
            icon: "video.fill",
            configuration: PackageConfiguration(
                identifier: "com.company.teams.backgrounds",
                version: "1.0",
                installLocation: "~/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads",
                includePostinstall: true
            )
        ),
        PackageTemplate(
            name: "Deploy Configuration Files",
            icon: "doc.badge.gearshape",
            configuration: PackageConfiguration(
                identifier: "com.company.config.deployment",
                version: "1.0",
                installLocation: "/Library/Application Support/YourCompany",
                includePostinstall: true,
                preservePermissions: true,
                packageMode: .fileDeployment,
                createIntermediateFolders: true
            )
        )
    ]
    
    var allTemplates: [PackageTemplate] {
        defaultTemplates + templateManager.templates
    }
    
    var body: some View {
        HStack {
            Menu {
                if !defaultTemplates.isEmpty {
                    Section("Default Templates") {
                        ForEach(defaultTemplates) { template in
                            Button(action: { applyTemplate(template) }) {
                                Label(template.name, systemImage: template.icon)
                            }
                        }
                    }
                }
                
                if !templateManager.templates.isEmpty {
                    Section("Custom Templates") {
                        ForEach(templateManager.templates) { template in
                            Button(action: { applyTemplate(template) }) {
                                Label(template.name, systemImage: template.icon)
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("Clear Template") {
                    selectedTemplate = nil
                }
            } label: {
                HStack {
                    Image(systemName: selectedTemplate?.icon ?? "doc.text.fill")
                    Text(selectedTemplate?.name ?? "Select Template")
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primaryAction.opacity(0.1))
                .cornerRadius(6)
            }
            .frame(maxWidth: 200)
            
            Button("Save Current as Template") {
                showingSaveDialog = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(configuration.identifier.isEmpty)
            
            if selectedTemplate != nil {
                Button(action: resetToCleanState) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Clear template selection and reset to clean state")
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveTemplateDialog(
                configuration: configuration,
                templateManager: templateManager,
                isPresented: $showingSaveDialog
            )
        }
    }
    
    private func applyTemplate(_ template: PackageTemplate) {
        // Save original configuration before applying template
        if originalConfiguration == nil {
            originalConfiguration = configuration
        }
        selectedTemplate = template
        configuration = template.configuration
    }
    
    private func resetToCleanState() {
        // Reset to clean configuration
        configuration = PackageConfiguration()
        selectedTemplate = nil
        originalConfiguration = nil
    }
}

// Save Template Dialog
struct SaveTemplateDialog: View {
    let configuration: PackageConfiguration
    let templateManager: TemplateManager
    @Binding var isPresented: Bool
    @State private var templateName = ""
    @State private var selectedIcon = "doc.text.fill"
    
    let availableIcons = [
        "doc.text.fill", "app.fill", "folder.fill", "terminal.fill",
        "globe", "message.fill", "video.fill", "music.note",
        "photo.fill", "book.fill", "gamecontroller.fill", "hammer.fill"
    ]
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Save as Template")
                .font(Typography.headline())
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Template Name")
                    .font(Typography.body())
                TextField("Enter template name", text: $templateName)
                    .textFieldStyle(.roundedBorder)
                
                Text("Icon")
                    .font(Typography.body())
                    .padding(.top, Spacing.sm)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.sm) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color.primaryAction.opacity(0.2) : Color.cardBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color.primaryAction : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 400)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    let template = PackageTemplate(
                        name: templateName,
                        icon: selectedIcon,
                        configuration: configuration
                    )
                    templateManager.addTemplate(template)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(templateName.isEmpty)
            }
        }
        .padding(Spacing.lg)
        .frame(width: 450)
    }
}

// Package Mode Selector
struct PackageModeSelector: View {
    @Binding var packageMode: PackageMode
    @State private var showingInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                // Segmented Control
                Picker("Package Type", selection: $packageMode) {
                    ForEach(PackageMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                // Info button
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondaryText)
                        .font(.footnote)
                }
                .buttonStyle(.plain)
                .help("Learn more about package types")
                .popover(isPresented: $showingInfo) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Package Types")
                            .font(Typography.headline())
                        
                        Divider()
                        
                        ForEach(PackageMode.allCases, id: \.self) { mode in
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Label(mode.displayName, systemImage: mode.icon)
                                    .font(Typography.subheadline())
                                    .foregroundColor(.primary)
                                Text(mode.description)
                                    .font(Typography.caption())
                                    .foregroundColor(.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                    .padding()
                    .frame(width: 350)
                }
                
                Spacer()
            }
            
            // Contextual help text based on selected mode
            Text(packageMode.description)
                .font(Typography.caption())
                .foregroundColor(.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Supporting Types
struct BuildStatusInfo {
    enum StatusType {
        case success
        case error
    }
    
    let type: StatusType
    let message: String
    let detail: String?
}


// Helper class for managing signing identities
class SigningIdentityManager: ObservableObject {
    @Published var identities: [SigningIdentity] = []
    @Published var isLoading = false
    
    func loadIdentities() {
        isLoading = true
        Task {
            let fetchedIdentities = await KeychainHelper.fetchSigningIdentities()
            await MainActor.run {
                self.identities = fetchedIdentities
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView(updaterController: SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil))
        .frame(width: 1000, height: 800)
}