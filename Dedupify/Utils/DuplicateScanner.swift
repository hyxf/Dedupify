//
//  DuplicateScanner.swift
//  FileDuplicateFinder
//

import Foundation
import CryptoKit

class DuplicateScanner {
    static func scanFolders(_ folders: [URL], progressCallback: @escaping (String) -> Void) async -> [DuplicateGroup] {
        var filesByHash: [String: [FileItem]] = [:]
        var processedCount = 0
        
        // 1. 收集所有文件
        var allFiles: [URL] = []
        
        for folder in folders {
            if Task.isCancelled { return [] }
            
            progressCallback("Enumerating: \(folder.lastPathComponent)...")
            
            guard let enumerator = FileManager.default.enumerator(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                allFiles.append(fileURL)
            }
        }
        
        let totalFiles = allFiles.count
        
        // 2. 计算哈希
        for (index, fileURL) in allFiles.enumerated() {
            if Task.isCancelled { return [] }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                
                guard let isRegularFile = resourceValues.isRegularFile,
                      isRegularFile,
                      let fileSize = resourceValues.fileSize,
                      fileSize > 0 else { continue }
                
                processedCount += 1
                
                // 降低UI刷新频率
                if processedCount % 20 == 0 {
                    let percent = Int((Double(index) / Double(totalFiles)) * 100)
                    progressCallback("Scanning \(percent)% - \(fileURL.lastPathComponent)")
                }
                
                let hash = try calculateHash(for: fileURL)
                let fileItem = FileItem(url: fileURL, size: Int64(fileSize), hash: hash)
                
                filesByHash[hash, default: []].append(fileItem)
            } catch {
                continue
            }
        }
        
        progressCallback("Finalizing results...")
        
        let duplicates = filesByHash
            .filter { $0.value.count > 1 }
            .map { DuplicateGroup(hash: $0.key, files: $0.value, size: $0.value.first?.size ?? 0) }
            .sorted { $0.duplicateSize > $1.duplicateSize }
        
        return duplicates
    }
    
    private static func calculateHash(for url: URL) throws -> String {
        let bufferSize = 8192
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        
        var hasher = SHA256()
        
        while autoreleasepool(invoking: {
            guard let data = try? file.read(upToCount: bufferSize), !data.isEmpty else {
                return false
            }
            hasher.update(data: data)
            return true
        }) {}
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    static func deleteFiles(_ files: [FileItem]) async throws -> Int64 {
        var totalSize: Int64 = 0
        
        for file in files {
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                totalSize += file.size
            } catch {
                print("Failed to delete: \(file.url.path)")
            }
        }
        
        return totalSize
    }
}
