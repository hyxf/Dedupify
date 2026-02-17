//
//  InitialViewModel.swift
//  FileDuplicateFinder
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

class InitialViewModel: ObservableObject {
    // 持有 AppState 引用以修改全局状态
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Business Logic
    
    func selectFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        
        panel.begin { [weak self] response in
            if response == .OK {
                DispatchQueue.main.async {
                    self?.updateSelectedFolders(panel.urls)
                }
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { [weak self] url, _ in
                if let url = url, url.hasDirectoryPath {
                    DispatchQueue.main.async {
                        self?.appendFolder(url)
                    }
                }
            }
        }
    }
    
    // MARK: - State Updates
    
    private func updateSelectedFolders(_ urls: [URL]) {
        withAnimation(.spring()) {
            appState.selectedFolders = urls
            appState.scanState = .selectingFolders
        }
    }
    
    private func appendFolder(_ url: URL) {
        withAnimation(.spring()) {
            appState.selectedFolders.append(url)
            appState.scanState = .selectingFolders
        }
    }
}
