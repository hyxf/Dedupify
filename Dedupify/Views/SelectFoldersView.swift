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
            // 左侧：文件夹列表
            VStack(spacing: 0) {
                HStack {
                    Button(action: { appState.reset() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Selected Folders")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.2))
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(appState.selectedFolders, id: \.self) { folder in
                            FolderRow(folder: folder) {
                                // 逻辑委托给 ViewModel
                                viewModel.removeFolder(folder)
                            }
                        }
                        
                        Button(action: { viewModel.addMoreFolders() }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add More")
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
            .frame(width: 380)
            .background(Color.black.opacity(0.1))
            
            // 右侧：准备扫描
            ZStack {
                VStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 240, height: 240)
                            .matchedGeometryEffect(id: "CenterOrb", in: namespace)
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("Ready to Scan")
                        .font(.largeTitle)
                        .fontWeight(.light)
                        .foregroundColor(.white)
                    
                    Text("\(appState.selectedFolders.count) folders selected")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 30)
                    
                    Button(action: { viewModel.startScan() }) {
                        Text("Start Scan")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(25)
                            .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 50)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Helper View 保持不变，因为它只是纯 UI 组件
struct FolderRow: View {
    let folder: URL
    let onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue.opacity(0.8))
            
            VStack(alignment: .leading) {
                Text(folder.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Text(folder.path)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(isHovering ? 0.1 : 0.05))
        .cornerRadius(8)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
    }
}
