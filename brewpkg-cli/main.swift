#!/usr/bin/env swift
//
//  main.swift
//  brewpkg-cli
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

struct CLIConfiguration: Codable {
    var identifier: String = ""
    var version: String = "1.0"
    var installLocation: String = "/Applications"
    var signingIdentity: String?
    var includePreinstall: Bool = false
    var includePostinstall: Bool = false
    var preservePermissions: Bool = false
    var inputPath: String = ""
    var outputPath: String = ""
    var verbose: Bool = false
    var jsonOutput: Bool = false
}

struct CLIResult: Codable {
    let success: Bool
    let message: String
    let outputPath: String?
    let error: String?
}

class BrewPkgCLI {
    private var configuration = CLIConfiguration()
    
    func run() {
        parseArguments()
        
        if configuration.inputPath.isEmpty || configuration.outputPath.isEmpty || configuration.identifier.isEmpty {
            if !configuration.jsonOutput {
                printUsage()
                exit(1)
            } else {
                outputJSON(CLIResult(
                    success: false,
                    message: "Missing required arguments",
                    outputPath: nil,
                    error: "Input path, output path, and identifier are required"
                ))
                exit(1)
            }
        }
        
        buildPackage()
    }
    
    private func parseArguments() {
        let arguments = CommandLine.arguments
        var i = 1
        
        while i < arguments.count {
            let arg = arguments[i]
            
            switch arg {
            case "-i", "--identifier":
                if i + 1 < arguments.count {
                    configuration.identifier = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                
            case "-v", "--version":
                if i + 1 < arguments.count {
                    configuration.version = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                
            case "-l", "--location":
                if i + 1 < arguments.count {
                    configuration.installLocation = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                
            case "-s", "--sign":
                if i + 1 < arguments.count {
                    configuration.signingIdentity = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                
            case "-p", "--input":
                if i + 1 < arguments.count {
                    configuration.inputPath = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                
            case "-o", "--output":
                if i + 1 < arguments.count {
                    configuration.outputPath = arguments[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                
            case "--preinstall":
                configuration.includePreinstall = true
                i += 1
                
            case "--postinstall":
                configuration.includePostinstall = true
                i += 1
                
            case "--preserve-permissions":
                configuration.preservePermissions = true
                i += 1
                
            case "--verbose":
                configuration.verbose = true
                i += 1
                
            case "--json":
                configuration.jsonOutput = true
                i += 1
                
            case "-h", "--help":
                printUsage()
                exit(0)
                
            default:
                if !configuration.jsonOutput {
                    print("Unknown argument: \\(arg)")
                }
                i += 1
            }
        }
    }
    
    private func printUsage() {
        let usage = \"\"\"
        brewpkg-cli - Command-line interface for creating macOS installer packages
        
        Usage: brewpkg-cli [OPTIONS]
        
        Required Options:
            -i, --identifier ID          Package identifier (e.g., com.example.app)
            -p, --input PATH            Input file or directory (DMG, ZIP, .app, or directory)
            -o, --output PATH           Output package path (.pkg)
        
        Optional Options:
            -v, --version VERSION        Package version (default: 1.0)
            -l, --location PATH          Install location (default: /Applications)
            -s, --sign IDENTITY         Signing identity for code signing
            --preinstall                Include preinstall script
            --postinstall               Include postinstall script
            --preserve-permissions      Preserve file permissions
            --verbose                   Verbose output
            --json                      Output results as JSON
            -h, --help                  Show this help message
        
        Examples:
            brewpkg-cli -i com.example.app -p MyApp.dmg -o MyApp.pkg
            brewpkg-cli -i com.example.tool -v 2.0 -l /usr/local/bin -p tool.zip -o tool.pkg
            brewpkg-cli -i com.example.app -p MyApp.app -o MyApp.pkg --sign "Developer ID"
        \"\"\"
        print(usage)
    }
    
    private func buildPackage() {
        // Find the engine script
        let enginePath = findEngineScript()
        
        guard FileManager.default.fileExists(atPath: enginePath) else {
            let error = "Build engine script not found at: \\(enginePath)"
            if configuration.jsonOutput {
                outputJSON(CLIResult(
                    success: false,
                    message: "Build failed",
                    outputPath: nil,
                    error: error
                ))
            } else {
                print("Error: \\(error)")
            }
            exit(1)
        }
        
        // Prepare arguments
        var args: [String] = []
        args.append(contentsOf: ["-i", configuration.identifier])
        args.append(contentsOf: ["-v", configuration.version])
        args.append(contentsOf: ["-l", configuration.installLocation])
        args.append(contentsOf: ["-p", configuration.inputPath])
        args.append(contentsOf: ["-o", configuration.outputPath])
        
        if let signingIdentity = configuration.signingIdentity {
            args.append(contentsOf: ["-s", signingIdentity])
        }
        
        if configuration.includePreinstall {
            args.append("--preinstall")
        }
        
        if configuration.includePostinstall {
            args.append("--postinstall")
        }
        
        if configuration.preservePermissions {
            args.append("--preserve-permissions")
        }
        
        if configuration.verbose && !configuration.jsonOutput {
            args.append("--verbose")
        }
        
        // Run the build
        let process = Process()
        process.executableURL = URL(fileURLWithPath: enginePath)
        process.arguments = args
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        if !configuration.jsonOutput {
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
        } else {
            process.standardOutput = outputPipe
            process.standardError = errorPipe
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                if configuration.jsonOutput {
                    outputJSON(CLIResult(
                        success: true,
                        message: "Package created successfully",
                        outputPath: configuration.outputPath,
                        error: nil
                    ))
                } else if !configuration.verbose {
                    print("Package created successfully: \\(configuration.outputPath)")
                }
            } else {
                var errorMessage = "Build failed with exit code: \\(process.terminationStatus)"
                
                if configuration.jsonOutput {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
                        errorMessage = error
                    }
                    
                    outputJSON(CLIResult(
                        success: false,
                        message: "Build failed",
                        outputPath: nil,
                        error: errorMessage
                    ))
                }
                exit(process.terminationStatus)
            }
        } catch {
            let errorMessage = "Failed to run build process: \\(error.localizedDescription)"
            
            if configuration.jsonOutput {
                outputJSON(CLIResult(
                    success: false,
                    message: "Build failed",
                    outputPath: nil,
                    error: errorMessage
                ))
            } else {
                print("Error: \\(errorMessage)")
            }
            exit(1)
        }
    }
    
    private func findEngineScript() -> String {
        // First check if we're running from the app bundle
        if let bundlePath = Bundle.main.resourcePath {
            let engineInBundle = "\\(bundlePath)/brewpkg-engine.sh"
            if FileManager.default.fileExists(atPath: engineInBundle) {
                return engineInBundle
            }
        }
        
        // Check in the same directory as the CLI
        let cliPath = CommandLine.arguments[0]
        let cliDir = (cliPath as NSString).deletingLastPathComponent
        let engineInCLIDir = "\\(cliDir)/brewpkg-engine.sh"
        if FileManager.default.fileExists(atPath: engineInCLIDir) {
            return engineInCLIDir
        }
        
        // Check in Resources directory relative to CLI
        let engineInResources = "\\(cliDir)/../Resources/brewpkg-engine.sh"
        if FileManager.default.fileExists(atPath: engineInResources) {
            return engineInResources
        }
        
        // Default path for development
        return "/Users/ugurkoc/Desktop/GitHub/brewpkg/brewpkg/Resources/brewpkg-engine.sh"
    }
    
    private func outputJSON(_ result: CLIResult) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(result),
           let json = String(data: data, encoding: .utf8) {
            print(json)
        }
    }
}

// Run the CLI
let cli = BrewPkgCLI()
cli.run()