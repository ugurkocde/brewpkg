//
//  PackageConfiguration.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

enum PackageMode: String, Codable, CaseIterable {
    case application = "application"
    case fileDeployment = "fileDeployment"
    
    var displayName: String {
        switch self {
        case .application:
            return "Application"
        case .fileDeployment:
            return "File Deployment"
        }
    }
    
    var icon: String {
        switch self {
        case .application:
            return "app.badge"
        case .fileDeployment:
            return "folder.badge.plus"
        }
    }
    
    var description: String {
        switch self {
        case .application:
            return "Package apps (.app, .dmg, .zip) for standard macOS installation"
        case .fileDeployment:
            return "Deploy configuration files, scripts, or resources to specific paths on managed devices"
        }
    }
}

struct PackageConfiguration: Codable, Equatable, Hashable {
    var identifier: String
    var version: String
    var installLocation: String
    var signingIdentity: String?
    var includePreinstall: Bool
    var includePostinstall: Bool
    var preservePermissions: Bool
    var packageMode: PackageMode
    var createIntermediateFolders: Bool
    var preinstallScript: String
    var postinstallScript: String
    
    init(
        identifier: String = "",
        version: String = "1.0",
        installLocation: String = "/Applications",
        signingIdentity: String? = nil,
        includePreinstall: Bool = false,
        includePostinstall: Bool = false,
        preservePermissions: Bool = true,
        packageMode: PackageMode = .application,
        createIntermediateFolders: Bool = false,
        preinstallScript: String = "#!/bin/bash\n# Pre-installation script\necho \"Preparing installation...\"\nexit 0",
        postinstallScript: String = "#!/bin/bash\n# Post-installation script\necho \"Installation complete.\"\nexit 0"
    ) {
        self.identifier = identifier
        self.version = version
        self.installLocation = installLocation
        self.signingIdentity = signingIdentity
        self.includePreinstall = includePreinstall
        self.includePostinstall = includePostinstall
        self.preservePermissions = preservePermissions
        self.packageMode = packageMode
        self.createIntermediateFolders = createIntermediateFolders
        self.preinstallScript = preinstallScript
        self.postinstallScript = postinstallScript
    }
    
    var isValid: Bool {
        !identifier.isEmpty && !version.isEmpty && !installLocation.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if identifier.isEmpty {
            errors.append("Package identifier is required")
        } else if !identifier.contains(".") {
            errors.append("Package identifier should use reverse domain notation (e.g., com.example.app)")
        }
        
        if version.isEmpty {
            errors.append("Version is required")
        }
        
        if installLocation.isEmpty {
            errors.append("Install location is required")
        } else if !installLocation.hasPrefix("/") {
            errors.append("Install location must be an absolute path")
        }
        
        return errors
    }
}

extension PackageConfiguration {
    func buildArguments(inputPath: String, outputPath: String) -> [String] {
        var args: [String] = []
        
        args.append(contentsOf: ["-i", identifier])
        args.append(contentsOf: ["-v", version])
        args.append(contentsOf: ["-l", installLocation])
        args.append(contentsOf: ["-p", inputPath])
        args.append(contentsOf: ["-o", outputPath])
        
        if let signingIdentity = signingIdentity, !signingIdentity.isEmpty {
            args.append(contentsOf: ["-s", signingIdentity])
        }
        
        if includePreinstall {
            args.append("--preinstall")
        }
        
        if includePostinstall {
            args.append("--postinstall")
        }
        
        if preservePermissions {
            args.append("--preserve-permissions")
        }
        
        if packageMode == .fileDeployment {
            args.append("--file-deployment-mode")
            
            if createIntermediateFolders {
                args.append("--create-intermediate-folders")
            }
        }
        
        args.append("--verbose")
        
        return args
    }
}