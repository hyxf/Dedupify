//
//  FileDuplicateFinderApp.swift
//  FileDuplicateFinder
//

import SwiftUI

@main
struct FileDuplicateFinderApp: App {
    // 1. 初始化全局状态
    @StateObject private var appState = AppState()
    
    // 2. 声明 ViewModels (使用 StateObject 确保生命周期跟随 App)
    private let initialVM: InitialViewModel
    private let selectFoldersVM: SelectFoldersViewModel
    private let resultsVM: ResultsViewModel
    
    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        
        // 3. 注入依赖 (ViewModel 持有 AppState)
        self.initialVM = InitialViewModel(appState: state)
        self.selectFoldersVM = SelectFoldersViewModel(appState: state)
        self.resultsVM = ResultsViewModel(appState: state)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 4. 注入所有对象
                .environmentObject(appState)
                .environmentObject(initialVM)
                .environmentObject(selectFoldersVM)
                .environmentObject(resultsVM)
                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
