//
//  ContentView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Namespace private var animationNamespace // 关键：共享动画命名空间
    
    var body: some View {
        ZStack {
            // 全局背景
            AppBackground()
            
            VStack(spacing: 0) {
                // 顶部拖拽区域（避开红绿灯）
                Color.clear.frame(height: 38)
                    .contentShape(Rectangle())
                    .gesture(WindowDragGesture())
                
                Group {
                    switch appState.scanState {
                    case .initial:
                        InitialView(namespace: animationNamespace)
                    case .selectingFolders, .readyToScan:
                        SelectFoldersView(namespace: animationNamespace)
                    case .scanning:
                        ScanningView(namespace: animationNamespace)
                    case .noResults:
                        NoResultsView(namespace: animationNamespace)
                    case .resultsFound:
                        ResultsFoundView(namespace: animationNamespace)
                    case .completed:
                        ResultsView()
                            .transition(.opacity)
                    case .cleaned:
                        CleanedView(namespace: animationNamespace)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Helper Views

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.2),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // 纹理
            Rectangle()
                .fill(.white.opacity(0.02))
        }
        .ignoresSafeArea()
    }
}

struct WindowDragGesture: Gesture {
    var body: some Gesture {
        DragGesture()
            .onChanged { _ in
                if let event = NSApp.currentEvent {
                    NSApp.mainWindow?.performDrag(with: event)
                }
            }
    }
}
