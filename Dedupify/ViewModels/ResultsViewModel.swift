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
    
    // 单选逻辑
    func toggleFileSelection(_ file: FileItem, in group: DuplicateGroup) {
        if appState.selectedFiles.contains(file.id) {
            appState.selectedFiles.remove(file.id)
        } else {
            // 业务规则：不能全选，至少保留一个
            let currentSelectedCount = group.files.filter { appState.selectedFiles.contains($0.id) }.count
            if currentSelectedCount < group.files.count - 1 {
                appState.selectedFiles.insert(file.id)
            } else {
                print("Cannot select all files in a group. Must keep one.")
            }
        }
        appState.calculateTotalSelectedSize()
    }
    
    // 批量自动选择逻辑 (Refactored)
    func autoSelect(keep: AutoSelectRule) {
        appState.autoSelect(keep: keep)
    }
    
    // 取消全选逻辑 (Refactored)
    func deselectAll() {
        appState.selectedFiles.removeAll()
        appState.calculateTotalSelectedSize()
    }
    
    // 删除逻辑
    func removeSelected() {
        print("Remove button clicked. Selected files: \(appState.selectedFiles.count)")
        
        let filesToDelete = appState.duplicateGroups
            .flatMap { $0.files }
            .filter { appState.selectedFiles.contains($0.id) }
        
        guard !filesToDelete.isEmpty else { return }
        
        let urlsToDelete = filesToDelete.map { $0.url }
        
        NSWorkspace.shared.recycle(urlsToDelete) { [weak self] newURLs, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error recycling files: \(error.localizedDescription)")
                    self.deleteErrorMessage = "Could not move files to Trash. Please check Permissions.\nError: \(error.localizedDescription)"
                    self.showingDeleteAlert = true
                } else {
                    let deletedSize = filesToDelete.reduce(0) { $0 + $1.size }
                    withAnimation {
                        self.appState.cleanedSize = deletedSize
                        self.appState.scanState = .cleaned
                    }
                }
            }
        }
    }
}
