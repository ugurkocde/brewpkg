//
//  SigningIdentity.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

struct SigningIdentity: Identifiable, Hashable {
    let id: String
    let name: String
    let teamID: String?
    let expiryDate: Date?
    
    var displayName: String {
        if let teamID = teamID {
            return "\(name) (\(teamID))"
        }
        return name
    }
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate < Date()
    }
}

class KeychainHelper {
    static func fetchSigningIdentities() async -> [SigningIdentity] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let identities = self.fetchIdentitiesSync()
                continuation.resume(returning: identities)
            }
        }
    }
    
    private static func fetchIdentitiesSync() -> [SigningIdentity] {
        let task = Process()
        task.launchPath = "/usr/bin/security"
        task.arguments = ["find-identity", "-v"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            
            // Read data asynchronously to prevent blocking
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            // Parse and filter for Developer ID Installer certificates
            let allIdentities = parseSecurityOutput(output)
            return allIdentities.filter { identity in
                // Filter for Developer ID Installer certificates (for PKG signing)
                // Also allow "3rd Party Mac Developer Installer" for Mac App Store
                identity.name.contains("Developer ID Installer") ||
                identity.name.contains("3rd Party Mac Developer Installer")
            }
        } catch {
            print("Error fetching signing identities: \(error)")
            return []
        }
    }
    
    private static func parseSecurityOutput(_ output: String) -> [SigningIdentity] {
        var identities: [SigningIdentity] = []
        let lines = output.components(separatedBy: .newlines)
        
        // Pattern to match identity lines
        // Example: 1) ABCDEF1234567890ABCDEF1234567890ABCDEF12 "Developer ID Application: John Doe (TEAMID123)"
        let pattern = #"^\s*\d+\)\s+([0-9A-F]{40})\s+"([^"]+)"(?:\s+\(([^)]+)\))?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        for line in lines {
            guard let match = regex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) else {
                continue
            }
            
            let nsLine = line as NSString
            
            // Extract SHA-1 hash (ID)
            let idRange = match.range(at: 1)
            guard idRange.location != NSNotFound else { continue }
            let id = nsLine.substring(with: idRange)
            
            // Extract certificate name
            let nameRange = match.range(at: 2)
            guard nameRange.location != NSNotFound else { continue }
            let fullName = nsLine.substring(with: nameRange)
            
            // Try to extract team ID from the name
            var teamID: String?
            if let teamMatch = fullName.range(of: #"\(([A-Z0-9]+)\)$"#, options: .regularExpression) {
                teamID = String(fullName[teamMatch].dropFirst(1).dropLast(1))
            }
            
            // Clean name (remove team ID if present)
            let name = fullName.replacingOccurrences(of: #"\s+\([A-Z0-9]+\)$"#, with: "", options: .regularExpression)
            
            let identity = SigningIdentity(
                id: id,
                name: name,
                teamID: teamID,
                expiryDate: nil
            )
            
            identities.append(identity)
        }
        
        return identities
    }
}