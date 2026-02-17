//
//  SelectFoldersView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct SelectFoldersView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: SelectFoldersViewModel
    var namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：文件夹列表 (浅灰背景)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { appState.reset() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Selected Folders")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(appState.selectedFolders, id: \.self) { folder in
                            FolderRow(folder: folder) {
                                viewModel.removeFolder(folder)
                            }
                        }
                        
                        Button(action: { viewModel.addMoreFolders() }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add More")
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .frame(width: 320)
            .background(Color(nsColor: .alternatingContentBackgroundColors[0])) // 系统列表背景
            // 修复：使用 overlay 替代自定义的 border 扩展来实现右侧边框
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1),
                alignment: .trailing
            )
            
            // 右侧：准备扫描
            ZStack {
                VStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: 240, height: 240)
                            .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text("Ready to Scan")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.primary)
                    
                    Text("\(appState.selectedFolders.count) folders selected")
                        .foregroundColor(.secondary)
                        .padding(.bottom, 30)
                    
                    Button(action: { viewModel.startScan() }) {
                        Text("Start Scan")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 44)
                            .background(Color.blue)
                            .cornerRadius(22)
                            .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 50)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
    }
}

// Helper View
struct FolderRow: View {
    let folder: URL
    let onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(folder.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text(folder.path)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(isHovering ? Color.gray.opacity(0.1) : Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(isHovering ? 0.05 : 0), radius: 2, y: 1)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
    }
}
