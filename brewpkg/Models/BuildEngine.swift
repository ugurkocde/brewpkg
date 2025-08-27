//
//  BuildEngine.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation
import Combine

enum BuildState: Equatable {
    case idle
    case building
    case completed
    case failed(Error)
    
    static func == (lhs: BuildState, rhs: BuildState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.building, .building), (.completed, .completed):
            return true
        case (.failed(_), .failed(_)):
            return true
        default:
            return false
        }
    }
}

enum BuildError: LocalizedError {
    case engineNotFound
    case processFailure(Int32)
    case invalidInput
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .engineNotFound:
            return "Build engine script not found"
        case .processFailure(let code):
            return "Build process failed with exit code: \(code)"
        case .invalidInput:
            return "Invalid input file or directory"
        case .cancelled:
            return "Build was cancelled"
        }
    }
}

class BuildEngine: ObservableObject {
    @Published var state: BuildState = .idle
    @Published var logOutput: String = ""
    @Published var progress: Double = 0.0
    
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var cancellables = Set<AnyCancellable>()
    
    func build(configuration: PackageConfiguration, inputURL: URL, outputURL: URL) async throws {
        if case .building = state { return }
        
        await MainActor.run {
            self.state = .building
            self.logOutput = ""
            self.progress = 0.0
        }
        
        do {
            try await performBuild(configuration: configuration, inputURL: inputURL, outputURL: outputURL)
            await MainActor.run {
                self.state = .completed
                self.progress = 1.0
            }
        } catch {
            await MainActor.run {
                self.state = .failed(error)
            }
            throw error
        }
    }
    
    private func performBuild(configuration: PackageConfiguration, inputURL: URL, outputURL: URL) async throws {
        // Find the engine script
        guard let engineURL = Bundle.main.url(forResource: "brewpkg-engine", withExtension: "sh") else {
            throw BuildError.engineNotFound
        }
        
        // Copy engine to temporary location for execution
        let tempDir = FileManager.default.temporaryDirectory
        let tempEngineURL = tempDir.appendingPathComponent("brewpkg-engine-\(UUID().uuidString).sh")
        
        try FileManager.default.copyItem(at: engineURL, to: tempEngineURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempEngineURL.path)
        
        // Create temp script files if needed
        var tempPreinstallURL: URL?
        var tempPostinstallURL: URL?
        
        defer {
            try? FileManager.default.removeItem(at: tempEngineURL)
            if let url = tempPreinstallURL {
                try? FileManager.default.removeItem(at: url)
            }
            if let url = tempPostinstallURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        // Create process
        let task = Process()
        task.executableURL = tempEngineURL
        var args = configuration.buildArguments(
            inputPath: inputURL.path,
            outputPath: outputURL.path
        )
        
        // Write custom script files if provided
        if configuration.includePreinstall && !configuration.preinstallScript.isEmpty {
            tempPreinstallURL = tempDir.appendingPathComponent("preinstall-\(UUID().uuidString).sh")
            try configuration.preinstallScript.write(to: tempPreinstallURL!, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempPreinstallURL!.path)
            args.append(contentsOf: ["--preinstall-file", tempPreinstallURL!.path])
        }
        
        if configuration.includePostinstall && !configuration.postinstallScript.isEmpty {
            tempPostinstallURL = tempDir.appendingPathComponent("postinstall-\(UUID().uuidString).sh")
            try configuration.postinstallScript.write(to: tempPostinstallURL!, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempPostinstallURL!.path)
            args.append(contentsOf: ["--postinstall-file", tempPostinstallURL!.path])
        }
        
        task.arguments = args
        
        // Debug: Log the command being executed
        print("[BUILD DEBUG] Executing: \(tempEngineURL.path)")
        print("[BUILD DEBUG] Arguments: \(args.joined(separator: " "))")
        
        // Setup pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        self.process = task
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        
        // Setup output handlers
        setupOutputHandlers()
        
        // Run the process
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                task.terminationHandler = { process in
                    DispatchQueue.main.async {
                        if process.terminationStatus == 0 {
                            continuation.resume()
                        } else if process.terminationStatus == SIGINT || process.terminationStatus == SIGTERM {
                            continuation.resume(throwing: BuildError.cancelled)
                        } else {
                            continuation.resume(throwing: BuildError.processFailure(process.terminationStatus))
                        }
                    }
                }
                
                try task.run()
                self.updateProgress(0.1)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func setupOutputHandlers() {
        // Handle standard output
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.appendLog(output)
                    self?.updateProgressFromOutput(output)
                }
            }
        }
        
        // Handle error output
        errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.appendLog(output)
                }
            }
        }
    }
    
    private func appendLog(_ text: String) {
        logOutput += text
        
        // Log to console for debugging
        print("[BUILD LOG] \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        
        // Keep log size reasonable
        if logOutput.count > 100000 {
            if let index = logOutput.index(logOutput.startIndex, offsetBy: 50000, limitedBy: logOutput.endIndex) {
                logOutput = String(logOutput[index...])
            }
        }
    }
    
    private func updateProgressFromOutput(_ output: String) {
        let lowercased = output.lowercased()
        
        if lowercased.contains("mounting") || lowercased.contains("extracting") {
            updateProgress(0.2)
        } else if lowercased.contains("expanding") {
            updateProgress(0.3)
        } else if lowercased.contains("copying") {
            updateProgress(0.4)
        } else if lowercased.contains("preparing package") {
            updateProgress(0.5)
        } else if lowercased.contains("creating") && lowercased.contains("script") {
            updateProgress(0.6)
        } else if lowercased.contains("pkgbuild") {
            updateProgress(0.7)
        } else if lowercased.contains("productbuild") {
            updateProgress(0.8)
        } else if lowercased.contains("signing") {
            updateProgress(0.85)
        } else if lowercased.contains("completed successfully") {
            updateProgress(0.95)
        }
    }
    
    private func updateProgress(_ value: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if value > self.progress {
                self.progress = value
            }
        }
    }
    
    func cancel() {
        process?.terminate()
        state = .failed(BuildError.cancelled)
    }
    
    func reset() {
        state = .idle
        logOutput = ""
        progress = 0.0
        process = nil
        outputPipe = nil
        errorPipe = nil
    }
    
    func clearLog() {
        logOutput = ""
    }
}