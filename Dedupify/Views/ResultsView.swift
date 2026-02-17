//
//  ResultsView.swift
//  FileDuplicateFinder
//

import SwiftUI
import QuickLookThumbnailing
import QuickLook

struct ResultsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: ResultsViewModel
    
    @State private var previewURL: URL?
    
    var body: some View {
        NavigationSplitView {
            // MARK: - 1. Sidebar (自动适配 Light Mode)
            List(selection: $viewModel.viewMode) {
                Section(header: Text("Filters")) {
                    NavigationLink(value: ResultsViewModel.ViewMode.allDuplicates) {
                        Label {
                            Text("All Duplicates")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: appState.totalDuplicateSize, countStyle: .file))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    
                    NavigationLink(value: ResultsViewModel.ViewMode.selected) {
                        Label {
                            Text("Selected")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: appState.totalSelectedSize, countStyle: .file))
                                .font(.caption)
                                .foregroundColor(appState.totalSelectedSize > 0 ? .white : .secondary)
                        } icon: {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(viewModel.viewMode == .selected ? .white : .green)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Dedupify")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    HStack {
                        Text("\(appState.duplicateGroups.count) groups found")
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
                }
                .background(.ultraThinMaterial)
            }
            
        } content: {
            // MARK: - 2. Middle List
            ZStack {
                // 白色背景
                Color.white.ignoresSafeArea()
                
                if viewModel.sortedGroups.isEmpty {
                    EmptyStateView(mode: viewModel.viewMode)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
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
                                // 添加分隔线，因为是白底
                                Divider()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(viewModel.viewMode == .selected ? "Selected Items" : "Duplicate Groups")
            .navigationSubtitle("\(viewModel.sortedGroups.count) items")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button("Select Newest Modified") { viewModel.autoSelect(keep: .oldest) }
                        Button("Select Oldest Modified") { viewModel.autoSelect(keep: .newest) }
                        Divider()
                        Button("Deselect All") { viewModel.deselectAll() }
                    } label: {
                        Label("Auto Select", systemImage: "wand.and.stars")
                    }
                    
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortBy) {
                            Text("Size").tag(ResultsViewModel.SortOption.size)
                            Text("Name").tag(ResultsViewModel.SortOption.name)
                            Text("Count").tag(ResultsViewModel.SortOption.count)
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .compatibleSpacePreview {
                if let file = viewModel.highlightedFile {
                    previewURL = file.url
                }
            }
            
        } detail: {
            // MARK: - 3. Detail Pane
            ZStack {
                // 详情页背景：稍微带点灰，区分层级
                Color(nsColor: .controlBackgroundColor).ignoresSafeArea()
                
                if let file = viewModel.highlightedFile {
                    FileDetailPane(file: file)
                } else if let group = viewModel.highlightedGroup {
                    GroupDetailSummary(group: group)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("Select a file to view details")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(ByteCountFormatter.string(fromByteCount: appState.totalSelectedSize, countStyle: .file))
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Selected for deletion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { viewModel.removeSelected() }) {
                            Text("Remove Selected")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(appState.selectedFiles.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.selectedFiles.isEmpty)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear { viewModel.onAppear() }
        .onChange(of: viewModel.viewMode) { _ in viewModel.onViewModeChanged() }
        .alert("Deletion Result", isPresented: $viewModel.showingDeleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.deleteErrorMessage)
        }
        .quickLookPreview($previewURL)
    }
}

// MARK: - Components (Updated for Light Mode)

struct FileThumbnailView: View {
    let url: URL
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    // 加个白色边框和阴影，像照片一样
                    .background(Color.white)
                    .border(Color.gray.opacity(0.2), width: 1)
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.3))
            }
        }
        .frame(height: 180)
        .onAppear { generateThumbnail() }
        .onChange(of: url) { _ in
            thumbnail = nil
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        let size = CGSize(width: 300, height: 300)
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: 2.0, representationTypes: .thumbnail)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { (thumbnail, error) in
            if let thumbnail = thumbnail {
                DispatchQueue.main.async { self.thumbnail = thumbnail.nsImage }
            }
        }
    }
}

struct FileDetailPane: View {
    let file: FileItem
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    FileThumbnailView(url: file.url)
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        .padding(.top, 20)
                        .onTapGesture { NSWorkspace.shared.open(file.url) }
                    
                    Text(file.name)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal)
                        .textSelection(.enabled)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Size", value: file.sizeFormatted)
                    DetailRow(label: "Kind", value: file.url.pathExtension.uppercased())
                    
                    if let modDate = file.modificationDate {
                        DetailRow(label: "Modified", value: modDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let createDate = file.creationDate {
                         DetailRow(label: "Created", value: createDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Path")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text(file.path)
                            .font(.system(size: 13))
                            .foregroundColor(.primary.opacity(0.8))
                            .lineLimit(6)
                            .textSelection(.enabled)
                    }
                    .padding(.top, 4)
                    
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([file.url])
                    }) {
                        Label("Reveal in Finder", systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
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
            // Group Header
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 28, height: 28)
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Text(group.files.first?.name ?? "Unknown")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        let selectedCount = group.files.filter { selectedFiles.contains($0.id) }.count
                        if selectedCount > 0 {
                            Text("\(selectedCount)")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        } else {
                            Text("\(group.files.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        Text(ByteCountFormatter.string(fromByteCount: group.duplicateSize, countStyle: .file))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                // 高亮逻辑
                .background(isGroupHighlighted ? Color.blue.opacity(0.1) : Color.white)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // File List
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(filesToShow) { file in
                        FileTreeRow(
                            file: file,
                            isChecked: selectedFiles.contains(file.id),
                            isHighlighted: highlightedFile?.id == file.id,
                            onCheck: { onToggleCheck(file) },
                            onSelect: { onSelectFile(file) }
                        )
                    }
                }
                .background(Color.gray.opacity(0.02)) // 展开后子列表稍微灰一点点
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
            Color.clear.frame(width: 44)
            
            Button(action: onCheck) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isChecked ? .blue : .gray.opacity(0.4))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
            
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: "doc")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.system(size: 13))
                            // 选中时文字变白，否则变黑
                            .foregroundColor(isHighlighted ? .white : .primary)
                            .lineLimit(1)
                        
                        Text(file.url.deletingLastPathComponent().lastPathComponent)
                            .font(.system(size: 11))
                            .foregroundColor(isHighlighted ? .white.opacity(0.8) : .secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                    
                    Spacer()
                    
                    Text(file.sizeFormatted)
                        .font(.caption2)
                        .foregroundColor(isHighlighted ? .white.opacity(0.8) : .secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHighlighted ? Color.blue : Color.clear)
            )
            .padding(.trailing, 8)
        }
    }
}

struct GroupDetailSummary: View {
    let group: DuplicateGroup
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("Duplicate Group")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text("Total potential waste")
                    .foregroundColor(.secondary)
            }
            
            Text(ByteCountFormatter.string(fromByteCount: group.duplicateSize, countStyle: .file))
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.orange)
            
            let selectedCount = group.files.filter { appState.selectedFiles.contains($0.id) }.count
            
            HStack {
                Image(systemName: selectedCount > 0 ? "checkmark.circle.fill" : "circle")
                Text("\(selectedCount) of \(group.files.count) selected to remove")
            }
            .font(.callout)
            .foregroundColor(selectedCount > 0 ? .blue : .secondary)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let mode: ResultsViewModel.ViewMode
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: mode == .selected ? "checkmark.circle" : "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.2))
            
            Text(mode == .selected ? "No files selected" : "No duplicates found")
                .font(.title3)
                .foregroundColor(.secondary)
            
            if mode == .selected {
                Text("Select files in the 'All Duplicates' view\nto mark them for removal.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

// 兼容性扩展
extension View {
    @ViewBuilder
    func compatibleSpacePreview(action: @escaping () -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.focusable()
                .onKeyPress(.space) {
                    action()
                    return .handled
                }
        } else {
            self.background(
                Button(action: action) { EmptyView() }
                .keyboardShortcut(.space, modifiers: [])
                .opacity(0)
                .frame(width: 0, height: 0)
            )
        }
    }
}
