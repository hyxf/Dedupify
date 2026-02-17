//
//  InitialView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct InitialView: View {
    @EnvironmentObject var viewModel: InitialViewModel
    var namespace: Namespace.ID
    
    @State private var isDraggingFile = false
    @State private var isMouseOver = false
    
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
            
            ZStack {
                // 静态外圈：浅色
                if !isActive {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        .frame(width: 280, height: 280)
                        .scaleEffect(1.1)
                }
                
                // 核心交互圈
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
                                    style: StrokeStyle(lineWidth: isActive ? 2 : 1, dash: isActive ? [10] : [])
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
                        
                        Text(isActive ? "Drop Here" : "Add Folders")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(isActive ? .blue : .gray)
                    }
                }
                .frame(width: 280, height: 280)
                .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                .scaleEffect(isActive ? 1.05 : 1.0)
            }
            .contentShape(Circle())
            .onHover { hovering in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
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
            .padding(.bottom, 60)
            
            Text("Drag & drop folders here to start scanning")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
