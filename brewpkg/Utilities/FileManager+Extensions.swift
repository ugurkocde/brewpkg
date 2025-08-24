//
//  FileManager+Extensions.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import Foundation

extension FileManager {
    func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func isExecutable(at url: URL) -> Bool {
        return isExecutableFile(atPath: url.path)
    }
    
    func createTemporaryDirectory(name: String = "brewpkg") -> URL? {
        let tempDir = temporaryDirectory.appendingPathComponent("\(name)-\(UUID().uuidString)")
        
        do {
            try createDirectory(at: tempDir, withIntermediateDirectories: true)
            return tempDir
        } catch {
            print("Failed to create temporary directory: \(error)")
            return nil
        }
    }
    
    func copyItemWithProgress(at sourceURL: URL, to destinationURL: URL, progress: ((Double) -> Void)? = nil) throws {
        _ = try self.sizeOfItem(at: sourceURL)
        
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &error) { (url) in
            do {
                try self.copyItem(at: url, to: destinationURL)
                progress?(1.0)
            } catch {
                print("Copy failed: \(error)")
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    private func sizeOfItem(at url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
        
        if resourceValues.isDirectory ?? false {
            var totalSize: Int64 = 0
            let enumerator = self.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
            
            while let fileURL = enumerator?.nextObject() as? URL {
                let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                totalSize += Int64(fileSize)
            }
            
            return totalSize
        } else {
            return Int64(resourceValues.fileSize ?? 0)
        }
    }
}