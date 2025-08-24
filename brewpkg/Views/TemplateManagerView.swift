//
//  TemplateManagerView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct TemplateManagerView: View {
    @Binding var configuration: PackageConfiguration
    @StateObject private var templateManager = TemplateManager()
    @State private var showingSaveDialog = false
    @State private var templateName = ""
    @State private var selectedTemplate: PackageTemplate?
    
    var body: some View {
        HStack(spacing: 12) {
            if !templateManager.templates.isEmpty {
                Picker("Template", selection: $selectedTemplate) {
                    Text("No Template").tag(PackageTemplate?.none)
                    Divider()
                    ForEach(templateManager.templates) { template in
                        Text(template.name).tag(PackageTemplate?.some(template))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .onChange(of: selectedTemplate) { template in
                    if let template = template {
                        loadTemplate(template)
                    }
                }
                .frame(minWidth: 150)
                
                if !templateManager.templates.isEmpty {
                    Menu {
                        ForEach(templateManager.templates) { template in
                            Button(template.name) {
                                templateManager.deleteTemplate(template)
                                if selectedTemplate?.id == template.id {
                                    selectedTemplate = nil
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .menuStyle(.borderlessButton)
                    .help("Delete template")
                }
            }
            
            Button(action: { showingSaveDialog = true }) {
                Label("Save Template", systemImage: "square.and.arrow.down")
            }
            .disabled(!configuration.isValid)
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveTemplateView(
                configuration: configuration,
                templateManager: templateManager,
                isPresented: $showingSaveDialog
            )
        }
    }
    
    private func loadTemplate(_ template: PackageTemplate) {
        configuration = template.configuration
        selectedTemplate = template
    }
}

struct SaveTemplateView: View {
    let configuration: PackageConfiguration
    let templateManager: TemplateManager
    @Binding var isPresented: Bool
    @State private var templateName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Save Template")
                .font(.headline)
            
            TextField("Template Name", text: $templateName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                Button("Save") {
                    let template = PackageTemplate(
                        name: templateName,
                        configuration: configuration
                    )
                    templateManager.addTemplate(template)
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .disabled(templateName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 150)
    }
}