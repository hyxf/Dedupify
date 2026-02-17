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
    
    // 逻辑修正：基于修改日期进行自动选择
    func autoSelect(keep: AutoSelectRule) {
        selectedFiles.removeAll()
        
        for group in duplicateGroups {
            guard group.files.count > 1 else { continue }
            
            let sortedFiles: [FileItem]
            
            switch keep {
            case .newest:
                // 保留最新的：按修改日期降序排列（新的在前），若日期相同或为空，则按路径兜底
                sortedFiles = group.files.sorted {
                    let date1 = $0.modificationDate ?? Date.distantPast
                    let date2 = $1.modificationDate ?? Date.distantPast
                    if date1 != date2 {
                        return date1 > date2
                    }
                    return $0.path > $1.path
                }
            case .oldest:
                // 保留最旧的：按修改日期升序排列（旧的在前）
                sortedFiles = group.files.sorted {
                    let date1 = $0.modificationDate ?? Date.distantFuture
                    let date2 = $1.modificationDate ?? Date.distantFuture
                    if date1 != date2 {
                        return date1 < date2
                    }
                    return $0.path < $1.path
                }
            }
            
            // 保留第一个（即符合规则的“正本”），选中其余所有的进行删除
            for i in 1..<sortedFiles.count {
                selectedFiles.insert(sortedFiles[i].id)
            }
        }
        calculateTotalSelectedSize()
    }
}
