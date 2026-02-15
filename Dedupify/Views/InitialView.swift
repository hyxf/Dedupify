//
//  InitialView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct InitialView: View {
    @EnvironmentObject var appState: AppState
    var namespace: Namespace.ID
    
    // 状态：是否正在拖拽文件经过
    @State private var isDraggingFile = false
    // 状态：鼠标指针是否悬停
    @State private var isMouseOver = false
    
    // 计算属性：只要满足任意一种悬停状态，就视为“激活”
    var isActive: Bool {
        return isDraggingFile || isMouseOver
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // CHANGED: Name updated
            Text("Dedupify")
                .font(.system(size: 48, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 60)
            
            ZStack {
                // 1. 背景脉冲波纹 (仅在未激活时缓慢跳动，激活时隐藏或放大)
                if !isActive {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 280, height: 280)
                        .scaleEffect(1.2)
                        .opacity(0.5)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                // 简单的呼吸效果
                            }
                        }
                }
                
                // 2. 核心交互圆圈
                ZStack {
                    // 圆形背景
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isActive
                                    ? [.blue.opacity(0.2), .blue.opacity(0.1)] // 激活变蓝
                                    : [.white.opacity(0.1), .white.opacity(0.05)], // 平时灰色
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? Color.blue.opacity(0.5) : Color.white.opacity(0.2),
                                    lineWidth: isActive ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isActive ? .blue.opacity(0.4) : .black.opacity(0.3),
                            radius: isActive ? 40 : 30,
                            y: 10
                        )
                    
                    // 图标和文字
                    VStack(spacing: 16) {
                        Image(systemName: "plus")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(isActive ? .white : .white.opacity(0.5))
                            // 图标单独的小旋转动画
                            .rotationEffect(.degrees(isActive ? 90 : 0))
                        
                        Text(isActive ? "Drop Here" : "Add Folders")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(isActive ? .white : .white.opacity(0.8))
                    }
                }
                .frame(width: 280, height: 280)
                // 关键修改：匹配几何效果
                .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                // 关键修改：整体缩放动画
                .scaleEffect(isActive ? 1.15 : 1.0)
            }
            // 设置点击区域形状
            .contentShape(Circle())
            // 鼠标指针悬停检测
            .onHover { hovering in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isMouseOver = hovering
                }
            }
            // 点击行为
            .onTapGesture {
                selectFolders()
            }
            // 文件拖拽检测
            .onDrop(of: ["public.file-url"], isTargeted: $isDraggingFile) { providers in
                // 拖拽结束，恢复状态
                withAnimation { isDraggingFile = false }
                handleDrop(providers: providers)
                return true
            }
            // 确保拖拽状态变化时也有动画
            .onChange(of: isDraggingFile) { newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    // 这里的动画由 scaleEffect 的 value 驱动，但显式调用确保顺滑
                }
            }
            .padding(.bottom, 60)
            
            Text("Drag & drop folders here to start scanning")
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .opacity(isActive ? 0.8 : 0.5)
            
            Spacer()
        }
    }
    
    func selectFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        
        panel.begin { response in
            if response == .OK {
                withAnimation(.spring()) {
                    appState.selectedFolders = panel.urls
                    appState.scanState = .selectingFolders
                }
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url, url.hasDirectoryPath {
                    DispatchQueue.main.async {
                        withAnimation(.spring()) {
                            appState.selectedFolders.append(url)
                            appState.scanState = .selectingFolders
                        }
                    }
                }
            }
        }
    }
}
