//
//  SelectFoldersViewModel.swift
//  FileDuplicateFinder
//

import SwiftUI
import Combine

class SelectFoldersViewModel: ObservableObject {
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Business Logic
    
    func addMoreFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.begin { [weak self] response in
            if response == .OK {
                self?.appendFolders(panel.urls)
            }
        }
    }
    
    func removeFolder(_ folder: URL) {
        if let idx = appState.selectedFolders.firstIndex(of: folder) {
            withAnimation {
                appState.selectedFolders.remove(at: idx)
                if appState.selectedFolders.isEmpty {
                    appState.scanState = .initial
                }
            }
        }
    }
    
    func startScan() {
        // 准备扫描状态
        withAnimation {
            appState.scanState = .scanning
            appState.isScanning = true
            appState.scannedFolderCount = appState.selectedFolders.count
        }
        
        // 启动异步任务
        appState.scanTask = Task { [weak self] in
            guard let self = self else { return }
            
            let results = await DuplicateScanner.scanFolders(self.appState.selectedFolders) { progress in
                DispatchQueue.main.async {
                    self.appState.scanProgress = progress
                }
            }
            
            if !Task.isCancelled {
                DispatchQueue.main.async {
                    self.finalizeScan(results: results)
                }
            }
        }
    }
    
    // MARK: - Internal Helpers
    
    private func appendFolders(_ urls: [URL]) {
        withAnimation {
            appState.selectedFolders.append(contentsOf: urls)
        }
    }
    
    private func finalizeScan(results: [DuplicateGroup]) {
        withAnimation {
            appState.duplicateGroups = results
            appState.totalDuplicateSize = results.reduce(0) { $0 + $1.duplicateSize }
            appState.isScanning = false
            appState.scanState = results.isEmpty ? .noResults : .resultsFound
        }
    }
}
