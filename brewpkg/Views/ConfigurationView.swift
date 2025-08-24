//
//  ConfigurationView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct ConfigurationView: View {
    @Binding var configuration: PackageConfiguration
    @State private var signingIdentities: [SigningIdentity] = []
    @State private var isLoadingIdentities = false
    @State private var showNoIdentitiesAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Basic Configuration
            GroupBox("Package Information") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Identifier:")
                            .frame(width: 100, alignment: .trailing)
                        TextField("com.example.app", text: $configuration.identifier)
                            .textFieldStyle(.roundedBorder)
                            .help("Reverse domain notation (e.g., com.company.product)")
                    }
                    
                    HStack {
                        Text("Version:")
                            .frame(width: 100, alignment: .trailing)
                        TextField("1.0", text: $configuration.version)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .help("Semantic version (e.g., 1.0.0)")
                    }
                    
                    HStack {
                        Text("Install Location:")
                            .frame(width: 100, alignment: .trailing)
                        TextField("/Applications", text: $configuration.installLocation)
                            .textFieldStyle(.roundedBorder)
                            .help("Absolute path where files will be installed")
                        
                        Menu {
                            Section("Applications") {
                                Button("/Applications") {
                                    configuration.installLocation = "/Applications"
                                }
                                Button("/Applications/Utilities") {
                                    configuration.installLocation = "/Applications/Utilities"
                                }
                            }
                            
                            Section("Command Line Tools") {
                                Button("/usr/local/bin") {
                                    configuration.installLocation = "/usr/local/bin"
                                }
                                Button("/opt/homebrew/bin (Apple Silicon)") {
                                    configuration.installLocation = "/opt/homebrew/bin"
                                }
                                Button("/opt/local/bin") {
                                    configuration.installLocation = "/opt/local/bin"
                                }
                            }
                            
                            Section("System Locations") {
                                Button("/Library/Application Support") {
                                    configuration.installLocation = "/Library/Application Support"
                                }
                                Button("/Library/PreferencePanes") {
                                    configuration.installLocation = "/Library/PreferencePanes"
                                }
                                Button("/Library/LaunchAgents") {
                                    configuration.installLocation = "/Library/LaunchAgents"
                                }
                            }
                            
                            Section("User Locations") {
                                Button("~/Library/Application Support") {
                                    configuration.installLocation = "~/Library/Application Support"
                                }
                            }
                        } label: {
                            Image(systemName: "location.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .help("Select common install location")
                        .frame(width: 20)
                    }
                }
            }
            
            // Signing
            GroupBox("Code Signing") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Identity:")
                            .frame(width: 100, alignment: .trailing)
                        
                        if isLoadingIdentities {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(height: 20)
                        } else {
                            Picker("", selection: $configuration.signingIdentity) {
                                Text("None (Unsigned)").tag(String?.none)
                                if !signingIdentities.isEmpty {
                                    Divider()
                                    ForEach(signingIdentities) { identity in
                                        Text(identity.displayName)
                                            .tag(String?.some(identity.name))
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            
                            Button(action: loadSigningIdentities) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderless)
                            .help("Refresh signing identities")
                        }
                    }
                    
                    if let identity = configuration.signingIdentity, !identity.isEmpty {
                        HStack {
                            Text("")
                                .frame(width: 100)
                            Label("Package will be signed", systemImage: "checkmark.seal")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Options
            GroupBox("Build Options") {
                HStack(spacing: 20) {
                    Spacer()
                        .frame(width: 80)
                    
                    Toggle("Preinstall", isOn: $configuration.includePreinstall)
                        .help("Add a script that runs before installation")
                    
                    Toggle("Postinstall", isOn: $configuration.includePostinstall)
                        .help("Add a script that runs after installation")
                    
                    Toggle("Preserve Permissions", isOn: $configuration.preservePermissions)
                        .help("Maintain original file permissions and extended attributes")
                    
                    Spacer()
                }
                .toggleStyle(.checkbox)
            }
        }
        .onAppear {
            loadSigningIdentities()
        }
        .alert("No Signing Identities", isPresented: $showNoIdentitiesAlert) {
            Button("OK") { }
        } message: {
            Text("No code signing identities were found. You can still create unsigned packages.")
        }
    }
    
    private func loadSigningIdentities() {
        isLoadingIdentities = true
        
        Task {
            let identities = await KeychainHelper.fetchSigningIdentities()
            
            await MainActor.run {
                self.signingIdentities = identities
                self.isLoadingIdentities = false
                
                if identities.isEmpty {
                    self.showNoIdentitiesAlert = true
                }
            }
        }
    }
}