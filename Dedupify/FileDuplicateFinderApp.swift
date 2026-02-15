//
//  FileDuplicateFinderApp.swift
//  FileDuplicateFinder
//

import SwiftUI

@main
struct FileDuplicateFinderApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                // 设置窗口的最小尺寸和默认尺寸为 900x600
                // 添加 maxWidth/maxHeight: .infinity 以允许用户拉伸窗口
                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
