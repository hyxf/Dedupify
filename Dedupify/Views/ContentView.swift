//
//  ContentView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            // 全局背景：亮色风格
            AppBackground()
            
            VStack(spacing: 0) {
                // 顶部拖拽区域
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
        // 强制浅色模式 (如果系统是深色，App 依然保持亮色，或者删掉这行让其跟随系统)
        .preferredColorScheme(.light)
    }
}

// MARK: - Helper Views

struct AppBackground: View {
    var body: some View {
        ZStack {
            // 极简浅灰/白色渐变
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(red: 0.96, green: 0.97, blue: 0.99)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
