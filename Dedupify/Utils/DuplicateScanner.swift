//
//  DuplicateScanner.swift
//  FileDuplicateFinder
//

import Foundation
import CryptoKit

class DuplicateScanner {
    
    /// 扫描文件夹寻找重复文件
    /// 优化策略：
    /// 1. 遍历所有文件
    /// 2. 按文件大小分组（大小唯一的文件不可能是重复的，直接忽略）
    /// 3. 仅对大小相同的文件组计算哈希
    /// 4. UI 刷新限流
    static func scanFolders(_ folders: [URL], progressCallback: @escaping (String) -> Void) async -> [DuplicateGroup] {
        // 用于 UI 限流的时间戳
        var lastUpdateTime = Date()
        
        // 内部辅助函数：限流发送进度
        func reportProgress(_ message: String, force: Bool = false) async {
            let now = Date()
            // 每 0.1 秒或者强制刷新时才更新 UI，防止主线程卡死
            if force || now.timeIntervalSince(lastUpdateTime) > 0.1 {
                progressCallback(message)
                lastUpdateTime = now
                // 关键：主动让出时间片，让主线程有机会响应 UI 事件
                await Task.yield()
            }
        }
        
        // --- 第一步：收集所有文件并按大小分组 ---
        await reportProgress("Scanning directory structure...", force: true)
        
        var filesBySize: [Int64: [URL]] = [:]
        var scannedFileCount = 0
        
        for folder in folders {
            if Task.isCancelled { return [] }
            
            // 使用同步辅助函数避免 Swift 6 并发错误
            let files = collectFiles(from: folder)
            
            for url in files {
                // 快速获取文件大小，不读取内容
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    filesBySize[Int64(size), default: []].append(url)
                }
                scannedFileCount += 1
            }
            
            await reportProgress("Found \(scannedFileCount) files...")
        }
        
        // --- 第二步：筛选出“潜在重复”的文件 ---
        // 只有大小相同且数量大于1的文件组才可能是重复的
        // 这一步能过滤掉 90% 以上的数据
        let potentialGroups = filesBySize.filter { $0.value.count > 1 }
        
        // 统计需要哈希计算的文件总数
        let totalFilesToHash = potentialGroups.values.reduce(0) { $0 + $1.count }
        var processedHashCount = 0
        
        if totalFilesToHash == 0 {
            return []
        }
        
        // --- 第三步：计算哈希并精确匹配 ---
        var filesByHash: [String: [FileItem]] = [:]
        
        for (size, urls) in potentialGroups {
            if Task.isCancelled { return [] }
            
            for url in urls {
                if Task.isCancelled { return [] }
                
                processedHashCount += 1
                
                // 更新进度
                let percent = Int((Double(processedHashCount) / Double(totalFilesToHash)) * 100)
                await reportProgress("Comparing content \(percent)% - \(url.lastPathComponent)")
                
                do {
                    // 计算哈希
                    let hash = try calculateHash(for: url)
                    let fileItem = FileItem(url: url, size: size, hash: hash)
                    filesByHash[hash, default: []].append(fileItem)
                } catch {
                    print("Error hashing file: \(url.path) - \(error)")
                    continue
                }
            }
        }
        
        await reportProgress("Finalizing results...", force: true)
        
        // --- 第四步：组装结果 ---
        let duplicates = filesByHash
            .filter { $0.value.count > 1 }
            .map { DuplicateGroup(hash: $0.key, files: $0.value, size: $0.value.first?.size ?? 0) }
            .sorted { $0.duplicateSize > $1.duplicateSize }
        
        return duplicates
    }
    
    // MARK: - Synchronous Helper
    // 将 NSEnumerator 的使用隔离在同步上下文中
    private static func collectFiles(from folder: URL) -> [URL] {
        var files: [URL] = []
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        
        for case let fileURL as URL in enumerator {
            // 确保是普通文件
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if resourceValues.isRegularFile == true {
                    files.append(fileURL)
                }
            } catch {
                continue
            }
        }
        return files
    }
    
    private static func calculateHash(for url: URL) throws -> String {
        // 使用较大的缓冲区 (32KB) 提高大文件读取性能
        let bufferSize = 32768
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
