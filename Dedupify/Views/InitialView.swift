//
//  InitialView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct InitialView: View {
    @EnvironmentObject var viewModel: InitialViewModel
    var namespace: Namespace.ID
    
    // 纯 UI 交互状态（拖拽高亮、鼠标悬停）保留在 View 中，因为这不涉及业务数据
    @State private var isDraggingFile = false
    @State private var isMouseOver = false
    
    var isActive: Bool {
        return isDraggingFile || isMouseOver
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Dedupify")
                .font(.system(size: 48, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 60)
            
            ZStack {
                if !isActive {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 280, height: 280)
                        .scaleEffect(1.2)
                        .opacity(0.5)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            }
                        }
                }
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isActive
                                    ? [.blue.opacity(0.2), .blue.opacity(0.1)]
                                    : [.white.opacity(0.1), .white.opacity(0.05)],
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
                    
                    VStack(spacing: 16) {
                        Image(systemName: "plus")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(isActive ? .white : .white.opacity(0.5))
                            .rotationEffect(.degrees(isActive ? 90 : 0))
                        
                        Text(isActive ? "Drop Here" : "Add Folders")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(isActive ? .white : .white.opacity(0.8))
                    }
                }
                .frame(width: 280, height: 280)
                .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                .scaleEffect(isActive ? 1.15 : 1.0)
            }
            .contentShape(Circle())
            .onHover { hovering in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isMouseOver = hovering
                }
            }
            // 逻辑委托给 ViewModel
            .onTapGesture {
                viewModel.selectFolders()
            }
            // 逻辑委托给 ViewModel
            .onDrop(of: ["public.file-url"], isTargeted: $isDraggingFile) { providers in
                withAnimation { isDraggingFile = false }
                viewModel.handleDrop(providers: providers)
                return true
            }
            .onChange(of: isDraggingFile) { newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { }
            }
            .padding(.bottom, 60)
            
            Text("Drag & drop folders here to start scanning")
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .opacity(isActive ? 0.8 : 0.5)
            
            Spacer()
        }
    }
}
