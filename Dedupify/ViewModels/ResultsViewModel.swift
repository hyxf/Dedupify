//
//  ResultsViewModel.swift
//  FileDuplicateFinder
//

import SwiftUI
import Combine

class ResultsViewModel: ObservableObject {
    private var appState: AppState
    
    // ViewModel 自身的 UI 状态
    @Published var viewMode: ViewMode = .allDuplicates
    @Published var expandedGroups: Set<UUID> = []
    @Published var highlightedFile: FileItem?
    @Published var highlightedGroup: DuplicateGroup?
    @Published var sortBy: SortOption = .size
    
    // 错误处理状态
    @Published var showingDeleteAlert = false
    @Published var deleteErrorMessage = ""
    
    enum ViewMode {
        case allDuplicates
        case selected
    }
    
    enum SortOption {
        case size, name, count
        
        var title: String {
            switch self {
            case .size: return "Size"
            case .name: return "Name"
            case .count: return "Count"
            }
        }
    }
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Logic & Calculations
    
    var sortedGroups: [DuplicateGroup] {
        let filteredGroups: [DuplicateGroup]
        
        switch viewMode {
        case .allDuplicates:
            filteredGroups = appState.duplicateGroups
        case .selected:
            filteredGroups = appState.duplicateGroups.filter { group in
                group.files.contains { appState.selectedFiles.contains($0.id) }
            }
        }
        
        switch sortBy {
        case .size: return filteredGroups.sorted { $0.duplicateSize > $1.duplicateSize }
        case .name: return filteredGroups.sorted { ($0.files.first?.name ?? "") < ($1.files.first?.name ?? "") }
        case .count: return filteredGroups.sorted { $0.files.count > $1.files.count }
        }
    }
    
    // MARK: - User Actions
    
    func onAppear() {
        if expandedGroups.isEmpty {
            expandedGroups = Set(appState.duplicateGroups.map { $0.id })
        }
        if highlightedGroup == nil && highlightedFile == nil {
            highlightedGroup = sortedGroups.first
        }
    }
    
    func onViewModeChanged() {
        expandedGroups = Set(sortedGroups.map { $0.id })
    }
    
    func toggleExpand(group: DuplicateGroup) {
        if expandedGroups.contains(group.id) {
            expandedGroups.remove(group.id)
        } else {
            expandedGroups.insert(group.id)
        }
        highlightedGroup = group
        highlightedFile = nil
    }
    
    func selectFile(_ file: FileItem) {
        highlightedFile = file
        highlightedGroup = nil
    }
    
    func toggleFileSelection(_ file: FileItem, in group: DuplicateGroup) {
        if appState.selectedFiles.contains(file.id) {
            appState.selectedFiles.remove(file.id)
        } else {
            let currentSelectedCount = group.files.filter { appState.selectedFiles.contains($0.id) }.count
            if currentSelectedCount < group.files.count - 1 {
                appState.selectedFiles.insert(file.id)
            } else {
                print("Cannot select all files in a group. Must keep one.")
            }
        }
        appState.calculateTotalSelectedSize()
    }
    
    func autoSelect(keep: AutoSelectRule) {
        appState.autoSelect(keep: keep)
    }
    
    func deselectAll() {
        appState.selectedFiles.removeAll()
        appState.calculateTotalSelectedSize()
    }
    
    // 增强的删除逻辑：统计失败详情
    func removeSelected() {
        let filesToDelete = appState.duplicateGroups
            .flatMap { $0.files }
            .filter { appState.selectedFiles.contains($0.id) }
        
        guard !filesToDelete.isEmpty else { return }
        
        // 异步执行删除
        Task {
            var successCount = 0
            var failCount = 0
            var deletedSize: Int64 = 0
            var lastError: Error?
            
            for file in filesToDelete {
                do {
                    try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                    deletedSize += file.size
                    successCount += 1
                } catch {
                    print("Failed to delete \(file.path): \(error)")
                    failCount += 1
                    lastError = error
                }
            }
            
            // 更新 UI
            DispatchQueue.main.async {
                if failCount > 0 {
                    // 部分或全部失败
                    let message = "\(successCount) files moved to Trash.\n\(failCount) files failed to delete.\n\nError: \(lastError?.localizedDescription ?? "Unknown error")\n\nPlease check File Access Permissions."
                    self.deleteErrorMessage = message
                    self.showingDeleteAlert = true
                }
                
                // 如果至少有一个成功，就进入清理完成界面
                if successCount > 0 {
                    withAnimation {
                        self.appState.cleanedSize = deletedSize
                        self.appState.scanState = .cleaned
                    }
                }
            }
        }
    }
}
