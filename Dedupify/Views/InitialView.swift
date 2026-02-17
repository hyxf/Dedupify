//
//  InitialView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct InitialView: View {
    @EnvironmentObject var viewModel: InitialViewModel
    var namespace: Namespace.ID
    
    // 交互状态
    @State private var isDraggingFile = false
    @State private var isMouseOver = false
    
    // 动画状态：控制呼吸
    @State private var isPulsing = false
    
    var isActive: Bool {
        return isDraggingFile || isMouseOver
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Dedupify")
                .font(.system(size: 48, weight: .light, design: .default))
                .foregroundColor(.primary.opacity(0.8))
                .padding(.bottom, 60)
            
            // 核心区域
            ZStack {
                // =================================================
                // 1. 视觉层 (Visual Layer)
                // 负责所有动画效果，但不参与鼠标交互，彻底避免闪烁
                // =================================================
                ZStack {
                    // 外圈 (呼吸动画)
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        .frame(width: 280, height: 280)
                        .scaleEffect(isPulsing ? 1.15 : 1.05) // 持续呼吸
                        .opacity(isActive ? 0 : 1) // 激活时隐藏，使用 opacity 避免布局跳变
                        .animation(.easeInOut(duration: 0.3), value: isActive)
                    
                    // 内圈 (核心 Orb)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isActive
                                        ? [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]
                                        : [Color.white, Color.white],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isActive ? Color.blue : Color.gray.opacity(0.2),
                                        style: StrokeStyle(lineWidth: isActive ? 2 : 1, dash: isActive ? [8] : [])
                                    )
                            )
                            .shadow(
                                color: isActive ? .blue.opacity(0.2) : .black.opacity(0.05),
                                radius: isActive ? 20 : 10,
                                y: 5
                            )
                        
                        VStack(spacing: 16) {
                            Image(systemName: "plus")
                                .font(.system(size: 60, weight: .thin))
                                .foregroundColor(isActive ? .blue : .gray.opacity(0.4))
                                .rotationEffect(.degrees(isActive ? 90 : 0))
                                .scaleEffect(isActive ? 1.1 : 1.0)
                            
                            Text(isActive ? "Drop Here" : "Add Folders")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(isActive ? .blue : .gray)
                        }
                    }
                    .frame(width: 280, height: 280)
                    .scaleEffect(isActive ? 1.05 : 1.0) // 激活时轻微放大
                    .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isActive)
                }
                .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                .allowsHitTesting(false) // 关键：禁用视觉层的交互检测，防止动画干扰鼠标判定
                
                // =================================================
                // 2. 交互层 (Interaction Layer)
                // 透明、固定大小、覆盖在上方。负责接收所有事件。
                // =================================================
                Circle()
                    .fill(Color.clear) // 完全透明
                    .frame(width: 280, height: 280) // 尺寸固定，绝对不会变！
                    .contentShape(Circle()) // 定义交互形状
                    .onHover { hovering in
                        // 使用显式动画包裹状态改变
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isMouseOver = hovering
                        }
                    }
                    .onTapGesture {
                        viewModel.selectFolders()
                    }
                    .onDrop(of: ["public.file-url"], isTargeted: $isDraggingFile) { providers in
                        withAnimation { isDraggingFile = false }
                        viewModel.handleDrop(providers: providers)
                        return true
                    }
            }
            .padding(.bottom, 60)
            
            Text("Drag & drop folders here to start scanning")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .onAppear {
            // 启动呼吸动画
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
