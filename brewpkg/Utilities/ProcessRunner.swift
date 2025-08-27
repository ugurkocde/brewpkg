//
//  ProcessRunner.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

class ProcessRunner {
    static func run(
        command: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        currentDirectory: URL? = nil
    ) async throws -> (output: String, error: String, exitCode: Int32) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: command)
                task.arguments = arguments
                
                if let environment = environment {
                    task.environment = environment
                }
                
                if let currentDirectory = currentDirectory {
                    task.currentDirectoryURL = currentDirectory
                }
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                task.terminationHandler = { process in
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""
                    
                    continuation.resume(returning: (output, error, process.terminationStatus))
                }
                
                do {
                    try task.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func runWithProgress(
        command: String,
        arguments: [String] = [],
        outputHandler: @escaping (String) -> Void,
        errorHandler: @escaping (String) -> Void
    ) -> Process {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                DispatchQueue.main.async {
                    outputHandler(output)
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                DispatchQueue.main.async {
                    errorHandler(error)
                }
            }
        }
        
        return task
    }
}