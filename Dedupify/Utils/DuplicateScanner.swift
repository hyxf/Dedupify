//
//  DuplicateScanner.swift
//  FileDuplicateFinder
//

import Foundation
import CryptoKit

class DuplicateScanner {
    
    /// 扫描文件夹寻找重复文件
    /// 优化策略：
    /// 1. 遍历所有文件 -> 按大小分组
    /// 2. 大小相同 -> 计算局部哈希（快速筛选大文件）
    /// 3. 局部哈希相同 -> 计算全量哈希（确保准确性）
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
        // 对大小相同的文件，先读取部分字节进行比对，避免大文件直接全量读取
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
                
                // 计算局部哈希 (前 4KB + 中 4KB + 后 4KB)
                if let partialHash = try? calculatePartialHash(for: url) {
                    filesByPartialHash[partialHash, default: []].append(url)
                }
            }
            
            // 只有局部哈希也相同的，才进入下一轮全量哈希
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
            
            // 这一组文件大小相同、局部内容相同，必须全量哈希确保 100% 准确
            // 获取该组文件的大小（取第一个即可）
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
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if resourceValues.isRegularFile == true {
                    files.append(fileURL)
                }
            } catch { continue }
        }
        return files
    }
    
    /// 计算全量 SHA256
    private static func calculateHash(for url: URL) throws -> String {
        let bufferSize = 65536 // 64KB Buffer
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
    
    /// 计算局部哈希（快速指纹）
    /// 读取文件头、中、尾各 4KB 数据组合计算哈希，大幅减少 IO
    private static func calculatePartialHash(for url: URL) throws -> String {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
        let chunkSize: UInt64 = 4096 // 4KB
        
        var hasher = Insecure.MD5() // 局部哈希用 MD5 足够且更快，仅用于预筛选
        
        // 1. 读取头部
        if let data = try? file.read(upToCount: Int(chunkSize)) {
            hasher.update(data: data)
        }
        
        // 2. 读取中部（如果文件足够大）
        if fileSize > chunkSize * 2 {
            try? file.seek(toOffset: fileSize / 2)
            if let data = try? file.read(upToCount: Int(chunkSize)) {
                hasher.update(data: data)
            }
        }
        
        // 3. 读取尾部（如果文件足够大）
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
            // 使用 trashItem 相比 removeItem 更安全
            try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
            totalSize += file.size
        }
        
        return totalSize
    }
}
