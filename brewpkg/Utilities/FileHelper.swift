//
//  FileHelper.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation
import AppKit

struct FileInfo: Equatable {
    let url: URL
    let size: Int64
    let type: FileType
    let appName: String?
    let binaryName: String?
    let version: String?
    let appIcon: NSImage?
    
    enum FileType: Equatable {
        case diskImage
        case zipArchive
        case appBundle
        case directory
        case binary
        case unknown
        
        var icon: String {
            switch self {
            case .diskImage: return "opticaldiscdrive.fill"
            case .zipArchive: return "doc.zipper"
            case .appBundle: return "app.fill"
            case .directory: return "folder.fill"
            case .binary: return "terminal.fill"
            case .unknown: return "doc.fill"
            }
        }
        
        var description: String {
            switch self {
            case .diskImage: return "Disk Image"
            case .zipArchive: return "ZIP Archive"
            case .appBundle: return "Application Bundle"
            case .directory: return "Directory"
            case .binary: return "Executable"
            case .unknown: return "File"
            }
        }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var suggestedIdentifier: String {
        if let appName = appName {
            let cleanName = appName
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ".app", with: "")
                .lowercased()
            return "com.company.\(cleanName)"
        } else if let binaryName = binaryName {
            let cleanName = binaryName.lowercased()
            return "com.company.\(cleanName)"
        } else {
            let name = url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: " ", with: "")
                .lowercased()
            return "com.company.\(name)"
        }
    }
}

class FileHelper {
    static func analyzeFile(at url: URL) -> FileInfo {
        let fileManager = FileManager.default
        var size: Int64 = 0
        var type: FileInfo.FileType = .unknown
        var appName: String?
        var binaryName: String?
        var version: String?
        var appIcon: NSImage?
        
        // Get file size
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path) {
            size = attributes[.size] as? Int64 ?? 0
        }
        
        // Determine file type
        if url.hasDirectoryPath {
            if url.pathExtension == "app" {
                type = .appBundle
                appName = url.lastPathComponent
                version = getAppVersion(at: url)
                appIcon = getAppIcon(at: url)
            } else {
                type = .directory
                // Check for app bundle inside
                if let app = findAppBundle(in: url) {
                    appName = app.lastPathComponent
                    version = getAppVersion(at: app)
                    appIcon = getAppIcon(at: app)
                }
                // Check for binaries
                if let binary = findExecutable(in: url) {
                    binaryName = binary.lastPathComponent
                }
            }
        } else {
            switch url.pathExtension.lowercased() {
            case "dmg":
                type = .diskImage
            case "zip":
                type = .zipArchive
            case "":
                // Check if it's an executable
                if fileManager.isExecutableFile(atPath: url.path) {
                    type = .binary
                    binaryName = url.lastPathComponent
                }
            default:
                type = .unknown
            }
        }
        
        // Try to extract version from filename if not found
        if version == nil {
            version = extractVersionFromFilename(url.lastPathComponent)
        }
        
        return FileInfo(
            url: url,
            size: size,
            type: type,
            appName: appName,
            binaryName: binaryName,
            version: version,
            appIcon: appIcon
        )
    }
    
    private static func getAppVersion(at appURL: URL) -> String? {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        // Try CFBundleShortVersionString first, then CFBundleVersion
        if let version = plist["CFBundleShortVersionString"] as? String {
            return version
        } else if let version = plist["CFBundleVersion"] as? String {
            return version
        }
        
        return nil
    }
    
    private static func findAppBundle(in directory: URL) -> URL? {
        let fileManager = FileManager.default
        
        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        return contents.first { $0.pathExtension == "app" }
    }
    
    private static func findExecutable(in directory: URL) -> URL? {
        let fileManager = FileManager.default
        
        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isExecutableKey]) else {
            return nil
        }
        
        for url in contents {
            if let isExecutable = try? url.resourceValues(forKeys: [.isExecutableKey]).isExecutable,
               isExecutable == true {
                return url
            }
        }
        
        return nil
    }
    
    private static func extractVersionFromFilename(_ filename: String) -> String? {
        // Common version patterns in filenames
        let patterns = [
            #"v?(\d+\.\d+(?:\.\d+)?(?:\.\d+)?)"#,  // Matches 1.0, 1.0.0, 1.0.0.0
            #"_(\d+\.\d+(?:\.\d+)?)"#,              // Matches _1.0, _1.0.0
            #"-(\d+\.\d+(?:\.\d+)?)"#               // Matches -1.0, -1.0.0
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: filename, range: NSRange(location: 0, length: filename.count)) {
                let nsString = filename as NSString
                let versionRange = match.range(at: 1)
                return nsString.substring(with: versionRange)
            }
        }
        
        return nil
    }
    
    private static func getAppIcon(at appURL: URL) -> NSImage? {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        // Get icon file name
        if let iconName = plist["CFBundleIconFile"] as? String {
            let iconFileName = iconName.hasSuffix(".icns") ? iconName : "\(iconName).icns"
            let iconURL = appURL.appendingPathComponent("Contents/Resources/\(iconFileName)")
            return NSImage(contentsOf: iconURL)
        }
        
        return nil
    }
}