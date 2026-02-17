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
                // 限制最小尺寸，但允许用户拉大，去掉 maxWidth: .infinity 防止启动时自动撑满
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        // 关键修改：设置一个合理的默认启动尺寸 (宽 1000, 高 720)
        .defaultSize(width: 1000, height: 720)
        // 移除 .windowResizability(.contentSize)，避免它强制去匹配 infinity
    }
}
