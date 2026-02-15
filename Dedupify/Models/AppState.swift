//
//  AppState.swift
//  FileDuplicateFinder
//

import Foundation
import SwiftUI
import Combine

enum ScanState: Equatable {
    case initial
    case selectingFolders
    case readyToScan
    case scanning
    case noResults
    case resultsFound
    case completed
    case cleaned
}

enum AutoSelectRule {
    case newest
    case oldest
}

class AppState: ObservableObject {
    @Published var scanState: ScanState = .initial
    @Published var selectedFolders: [URL] = []
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var selectedFiles: Set<UUID> = []
    @Published var scannedFolderCount: Int = 0
    @Published var totalDuplicateSize: Int64 = 0
    @Published var totalSelectedSize: Int64 = 0
    @Published var cleanedSize: Int64 = 0
    @Published var isScanning: Bool = false
    @Published var scanProgress: String = "Preparing scan..."
    
    // 用于取消扫描任务
    var scanTask: Task<Void, Never>?
    
    func reset() {
        // 使用弹簧动画重置
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scanState = .initial
            selectedFolders = []
            duplicateGroups = []
            selectedFiles = []
            scannedFolderCount = 0
            totalDuplicateSize = 0
            totalSelectedSize = 0
            cleanedSize = 0
            isScanning = false
            scanProgress = "Preparing scan..."
        }
    }
    
    func stopScan() {
        scanTask?.cancel()
        isScanning = false
        withAnimation {
            scanState = .initial
        }
    }
    
    func calculateTotalSelectedSize() {
        var total: Int64 = 0
        for group in duplicateGroups {
            for file in group.files where selectedFiles.contains(file.id) {
                total += file.size
            }
        }
        totalSelectedSize = total
    }
    
    func autoSelect(keep: AutoSelectRule) {
        selectedFiles.removeAll()
        
        for group in duplicateGroups {
            guard group.files.count > 1 else { continue }
            
            // 这里使用路径字符串长度作为简单的排序演示
            // 实际生产中建议在 FileItem 增加 creationDate/modificationDate 并按日期排序
            let sortedFiles: [FileItem]
            switch keep {
            case .newest:
                // 模拟保留“最新”（假设较长的路径是较新的，或者按字母倒序）
                sortedFiles = group.files.sorted { $0.path > $1.path }
            case .oldest:
                sortedFiles = group.files.sorted { $0.path < $1.path }
            }
            
            // 保留第一个（即排在最前的），选中其余所有的进行删除
            for i in 1..<sortedFiles.count {
                selectedFiles.insert(sortedFiles[i].id)
            }
        }
        calculateTotalSelectedSize()
    }
}
