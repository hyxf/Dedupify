//
//  ResultsView.swift
//  FileDuplicateFinder
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ResultsViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - 1. Left Sidebar
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button(action: { appState.reset() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Start Over")
                    
                    Text("Exact Duplicates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider().background(Color.white.opacity(0.1))
                
                // Navigation Items
                ScrollView {
                    VStack(spacing: 4) {
                        SidebarButton(
                            title: "All Duplicates",
                            icon: "doc.on.doc",
                            size: appState.totalDuplicateSize,
                            isSelected: viewModel.viewMode == .allDuplicates
                        ) {
                            viewModel.viewMode = .allDuplicates
                        }
                        
                        SidebarButton(
                            title: "Selected",
                            icon: "checkmark.circle",
                            size: appState.totalSelectedSize,
                            isSelected: viewModel.viewMode == .selected,
                            accentColor: .green
                        ) {
                            viewModel.viewMode = .selected
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                }
                
                Spacer()
                
                // Bottom Status
                HStack {
                    Text("\(ByteCountFormatter.string(fromByteCount: appState.totalDuplicateSize, countStyle: .file)) in \(appState.duplicateGroups.count) groups")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
                .padding(12)
                .background(Color.black.opacity(0.3))
            }
            .frame(width: 200)
            .background(Color.black.opacity(0.2))
            
            Divider().background(Color.black)
            
            // MARK: - 2. Middle List (File Tree)
            VStack(spacing: 0) {
                // MARK: Toolbar
                HStack {
                    // 左侧：自动选择菜单
                    Menu {
                        // FIXED: 调用 ViewModel 方法，而非直接操作 AppState
                        Button("Select Newest") { viewModel.autoSelect(keep: .oldest) }
                        Button("Select Oldest") { viewModel.autoSelect(keep: .newest) }
                        Divider()
                        Button("Deselect All") {
                            viewModel.deselectAll()
                        }
                    } label: {
                        ToolbarButtonLabel(
                            title: "Auto Select",
                            icon: "wand.and.stars"
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 140)
                    
                    Spacer()
                    
                    // 右侧：排序菜单
                    Menu {
                        Button("Size") { viewModel.sortBy = .size }
                        Button("Name") { viewModel.sortBy = .name }
                        Button("Count") { viewModel.sortBy = .count }
                    } label: {
                        ToolbarButtonLabel(
                            title: "Sort: \(viewModel.sortBy.title)",
                            icon: "arrow.up.arrow.down"
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 140)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.03))
                .border(width: 1, edges: [.bottom], color: Color.black.opacity(0.6))
                
                // List Content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if viewModel.sortedGroups.isEmpty {
                            EmptyStateView(mode: viewModel.viewMode)
                        } else {
                            ForEach(viewModel.sortedGroups) { group in
                                GroupItemView(
                                    group: group,
                                    viewMode: viewModel.viewMode,
                                    isExpanded: viewModel.expandedGroups.contains(group.id),
                                    highlightedGroup: viewModel.highlightedGroup,
                                    highlightedFile: viewModel.highlightedFile,
                                    selectedFiles: appState.selectedFiles,
                                    onToggleExpand: {
                                        viewModel.toggleExpand(group: group)
                                    },
                                    onSelectFile: { file in
                                        viewModel.selectFile(file)
                                    },
                                    onToggleCheck: { file in
                                        viewModel.toggleFileSelection(file, in: group)
                                    }
                                )
                            }
                        }
                    }
                }
                .background(Color.white.opacity(0.02))
                
                // Bottom Status Bar for List
                HStack {
                    Text(viewModel.viewMode == .selected ? "\(appState.selectedFiles.count) files selected" : "\(appState.duplicateGroups.count) groups found")
                    Spacer()
                }
                .padding(8)
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .background(Color.black.opacity(0.2))
            }
            .frame(minWidth: 400, maxWidth: .infinity)
            .background(Color.black.opacity(0.1))
            
            Divider().background(Color.black)
            
            // MARK: - 3. Right Details Panel
            VStack(spacing: 0) {
                if let file = viewModel.highlightedFile {
                    FileDetailPane(file: file)
                } else if let group = viewModel.highlightedGroup {
                    GroupDetailSummary(group: group)
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.1))
                        Text("Select a file to view details")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top)
                        Spacer()
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Bottom Action Bar
                HStack {
                    VStack(alignment: .trailing) {
                        Text(ByteCountFormatter.string(fromByteCount: appState.totalSelectedSize, countStyle: .file))
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Selected")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.removeSelected() }) {
                        Text("Remove")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(appState.selectedFiles.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.selectedFiles.isEmpty)
                }
                .padding(16)
                .background(Color.black.opacity(0.2))
            }
            .frame(width: 270)
            .background(Color.black.opacity(0.1))
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: viewModel.viewMode) { _ in
            viewModel.onViewModeChanged()
        }
        // 错误提示弹窗
        .alert("Deletion Failed", isPresented: $viewModel.showingDeleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.deleteErrorMessage)
        }
    }
}

// MARK: - Component Views
// 组件视图保持不变
struct ToolbarButtonLabel: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .symbolRenderingMode(.monochrome)
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let size: Int64
    let isSelected: Bool
    var accentColor: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct GroupItemView: View {
    let group: DuplicateGroup
    let viewMode: ResultsViewModel.ViewMode
    let isExpanded: Bool
    let highlightedGroup: DuplicateGroup?
    let highlightedFile: FileItem?
    let selectedFiles: Set<UUID>
    
    let onToggleExpand: () -> Void
    let onSelectFile: (FileItem) -> Void
    let onToggleCheck: (FileItem) -> Void
    
    var isGroupHighlighted: Bool {
        highlightedGroup?.id == group.id
    }
    
    var filesToShow: [FileItem] {
        if viewMode == .selected {
            return group.files.filter { selectedFiles.contains($0.id) }
        } else {
            return group.files
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 24, height: 24)
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(group.files.first?.name ?? "Unknown")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        let selectedCount = group.files.filter { selectedFiles.contains($0.id) }.count
                        Text("\(selectedCount)")
                            .fontWeight(.medium)
                            .foregroundColor(selectedCount > 0 ? .blue : .white.opacity(0.3))
                        Text(" | ")
                            .foregroundColor(.white.opacity(0.2))
                        Text("\(group.files.count)")
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isGroupHighlighted ? Color.blue.opacity(0.2) : Color.white.opacity(0.02))
                .border(width: 1, edges: [.bottom], color: Color.black.opacity(0.3))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ForEach(filesToShow) { file in
                    FileTreeRow(
                        file: file,
                        isChecked: selectedFiles.contains(file.id),
                        isHighlighted: highlightedFile?.id == file.id,
                        onCheck: { onToggleCheck(file) },
                        onSelect: { onSelectFile(file) }
                    )
                    Divider().background(Color.white.opacity(0.05)).padding(.leading, 40)
                }
            }
        }
    }
}

struct FileTreeRow: View {
    let file: FileItem
    let isChecked: Bool
    let isHighlighted: Bool
    let onCheck: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onCheck) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? .blue : .white.opacity(0.2))
                    .frame(width: 40, height: 30)
            }
            .buttonStyle(.plain)
            
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: "doc")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text(file.url.deletingLastPathComponent().lastPathComponent)
                            .foregroundColor(.white.opacity(0.4))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.2))
                        Text(file.name)
                            .foregroundColor(isHighlighted ? .white : .white.opacity(0.9))
                    }
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.trailing, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(isHighlighted ? Color.blue.opacity(0.6) : Color.clear)
    }
}

struct FileDetailPane: View {
    let file: FileItem
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 90))
                            .foregroundColor(.blue.opacity(0.5))
                            .padding(.top, 40)
                            .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                        
                        Text(file.name)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Size", value: file.sizeFormatted)
                        DetailRow(label: "Kind", value: file.url.pathExtension.uppercased())
                        
                        if let date = try? file.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                            DetailRow(label: "Modified", value: date.formatted(date: .abbreviated, time: .shortened))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Path")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                            Text(file.path)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(6)
                                .textSelection(.enabled)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct GroupDetailSummary: View {
    let group: DuplicateGroup
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.on.doc")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.1))
                .padding(.bottom)
            
            let selectedCount = group.files.filter { appState.selectedFiles.contains($0.id) }.count
            
            Text("\(selectedCount) of \(group.files.count) selected")
                .font(.title3)
                .foregroundColor(selectedCount > 0 ? .blue : .white.opacity(0.9))
                .padding(.bottom, 4)
            
            Text("Total Wasted: \(ByteCountFormatter.string(fromByteCount: group.duplicateSize, countStyle: .file))")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 85, alignment: .trailing)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let mode: ResultsViewModel.ViewMode
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: mode == .selected ? "checkmark.circle" : "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.1))
            
            Text(mode == .selected ? "No files selected" : "No duplicates found")
                .foregroundColor(.white.opacity(0.5))
            
            if mode == .selected {
                Text("Select files in the 'All Duplicates' view to mark them for removal.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .frame(height: 300)
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat = 0, y: CGFloat = 0, w: CGFloat = 0, h: CGFloat = 0
            switch edge {
            case .top:
                x = rect.minX; y = rect.minY; w = rect.width; h = width
            case .bottom:
                x = rect.minX; y = rect.maxY - width; w = rect.width; h = width
            case .leading:
                x = rect.minX; y = rect.minY; w = width; h = rect.height
            case .trailing:
                x = rect.maxX - width; y = rect.minY; w = width; h = rect.height
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}
