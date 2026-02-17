//
//  DuplicateScanner.swift
//  FileDuplicateFinder
//

import Foundation
import CryptoKit

class DuplicateScanner {
    
    // 上架级优化：内置常见垃圾目录黑名单
    private static let ignoredDirectories: Set<String> = [
        "node_modules",
        ".git",
        ".svn",
        ".hg",
        "DerivedData",
        "build",
        "dist",
        "__pycache__",
        ".idea",
        ".vscode",
        "Pods",
        "Carthage"
    ]
    
    /// 扫描文件夹寻找重复文件
    static func scanFolders(_ folders: [URL], progressCallback: @escaping (String) -> Void) async -> [DuplicateGroup] {
        var lastUpdateTime = Date()
        
        func reportProgress(_ message: String, force: Bool = false) async {
            let now = Date()
            if force || now.timeIntervalSince(lastUpdateTime) > 0.1 {
                progressCallback(message)
                lastUpdateTime = now
                await Task.yield()
            }
        }
        
        // --- 第一步：收集文件并按大小分组 ---
        await reportProgress("Scanning directory structure...", force: true)
        
        var filesBySize: [Int64: [URL]] = [:]
        var scannedFileCount = 0
        
        for folder in folders {
            if Task.isCancelled { return [] }
            
            // 使用支持黑名单的收集函数
            let files = collectFiles(from: folder)
            for url in files {
                // 忽略 0 字节文件
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 {
                    filesBySize[Int64(size), default: []].append(url)
                }
                scannedFileCount += 1
            }
            await reportProgress("Found \(scannedFileCount) files...")
        }
        
        let sizeGroups = filesBySize.filter { $0.value.count > 1 }
        
        // --- 第二步：局部哈希预筛选 (Partial Hash) ---
        var potentialDuplicates: [[URL]] = []
        var totalFilesToPartialHash = sizeGroups.values.reduce(0) { $0 + $1.count }
        var processedPartialCount = 0
        
        for (_, urls) in sizeGroups {
            if Task.isCancelled { return [] }
            
            var filesByPartialHash: [String: [URL]] = [:]
            
            for url in urls {
                processedPartialCount += 1
                let percent = Int((Double(processedPartialCount) / Double(totalFilesToPartialHash)) * 100)
                await reportProgress("Pre-scanning \(percent)%...")
                
                if let partialHash = try? calculatePartialHash(for: url) {
                    filesByPartialHash[partialHash, default: []].append(url)
                }
            }
            
            for group in filesByPartialHash.values where group.count > 1 {
                potentialDuplicates.append(group)
            }
        }
        
        // --- 第三步：全量哈希精确匹配 ---
        var filesByFullHash: [String: [FileItem]] = [:]
        let totalFilesToFullHash = potentialDuplicates.reduce(0) { $0 + $1.count }
        var processedFullCount = 0
        
        for group in potentialDuplicates {
            if Task.isCancelled { return [] }
            
            let fileSize = (try? group.first?.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            
            for url in group {
                if Task.isCancelled { return [] }
                
                processedFullCount += 1
                let percent = Int((Double(processedFullCount) / Double(totalFilesToFullHash)) * 100)
                await reportProgress("Verifying content \(percent)% - \(url.lastPathComponent)")
                
                if let hash = try? calculateHash(for: url) {
                    let fileItem = FileItem(url: url, size: Int64(fileSize), hash: hash)
                    filesByFullHash[hash, default: []].append(fileItem)
                }
            }
        }
        
        await reportProgress("Finalizing results...", force: true)
        
        let duplicates = filesByFullHash
            .filter { $0.value.count > 1 }
            .map { DuplicateGroup(hash: $0.key, files: $0.value, size: $0.value.first?.size ?? 0) }
            .sorted { $0.duplicateSize > $1.duplicateSize }
        
        return duplicates
    }
    
    // MARK: - Helpers
    
    private static func collectFiles(from folder: URL) -> [URL] {
        var files: [URL] = []
        
        // 定义需要的键 (Array)
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        // 修复：显式转换为 Set，供 resourceValues 使用
        let keysSet = Set(keys)
        
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys, // 这里传 Array
            options: options,
            errorHandler: { url, error in
                print("Directory enumerator error at \(url): \(error)")
                return true 
            }
        ) else { return [] }
        
        for case let fileURL as URL in enumerator {
            do {
                // 修复：这里传 Set
                let resourceValues = try fileURL.resourceValues(forKeys: keysSet)
                
                // 1. 检查是否为目录，如果是黑名单目录，跳过其所有子内容
                if resourceValues.isDirectory == true {
                    if ignoredDirectories.contains(fileURL.lastPathComponent) {
                        enumerator.skipDescendants()
                    }
                    continue
                }
                
                // 2. 收集普通文件
                if resourceValues.isRegularFile == true {
                    files.append(fileURL)
                }
            } catch { continue }
        }
        return files
    }
    
    /// 计算全量 SHA256
    private static func calculateHash(for url: URL) throws -> String {
        let bufferSize = 65536
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            guard let data = try? file.read(upToCount: bufferSize), !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}
        
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
    
    /// 计算局部哈希
    private static func calculatePartialHash(for url: URL) throws -> String {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
        let chunkSize: UInt64 = 4096
        
        var hasher = Insecure.MD5()
        
        if let data = try? file.read(upToCount: Int(chunkSize)) {
            hasher.update(data: data)
        }
        
        if fileSize > chunkSize * 2 {
            try? file.seek(toOffset: fileSize / 2)
            if let data = try? file.read(upToCount: Int(chunkSize)) {
                hasher.update(data: data)
            }
        }
        
        if fileSize > chunkSize * 3 {
            try? file.seek(toOffset: max(0, fileSize - chunkSize))
            if let data = try? file.read(upToCount: Int(chunkSize)) {
                hasher.update(data: data)
            }
        }
        
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
    
    static func deleteFiles(_ files: [FileItem]) async throws -> Int64 {
        var totalSize: Int64 = 0
        for file in files {
            try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
            totalSize += file.size
        }
        return totalSize
    }
}
