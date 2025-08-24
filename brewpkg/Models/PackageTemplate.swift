//
//  PackageTemplate.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

struct PackageTemplate: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var configuration: PackageConfiguration
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, icon: String = "doc.text.fill", configuration: PackageConfiguration) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.configuration = configuration
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

class TemplateManager: ObservableObject {
    @Published var templates: [PackageTemplate] = []
    
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "brewpkg.templates"
    
    init() {
        loadTemplates()
    }
    
    func loadTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey),
              let decoded = try? JSONDecoder().decode([PackageTemplate].self, from: data) else {
            templates = []
            return
        }
        templates = decoded
    }
    
    func saveTemplates() {
        guard let encoded = try? JSONEncoder().encode(templates) else { return }
        userDefaults.set(encoded, forKey: templatesKey)
    }
    
    func addTemplate(_ template: PackageTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    func updateTemplate(_ template: PackageTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            var updatedTemplate = template
            updatedTemplate.updatedAt = Date()
            templates[index] = updatedTemplate
            saveTemplates()
        }
    }
    
    func deleteTemplate(_ template: PackageTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func exportTemplate(_ template: PackageTemplate, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(template)
        try data.write(to: url)
    }
    
    func importTemplate(from url: URL) throws -> PackageTemplate {
        let data = try Data(contentsOf: url)
        let template = try JSONDecoder().decode(PackageTemplate.self, from: data)
        return template
    }
}