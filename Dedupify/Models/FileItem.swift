//
//  FileItem.swift
//  FileDuplicateFinder
//

import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
    let hash: String
    
    // 新增：日期属性，用于自动选择逻辑
    let modificationDate: Date?
    let creationDate: Date?
    
    var isSelected: Bool = false
    
    // 初始化时读取日期信息
    init(url: URL, size: Int64, hash: String) {
        self.url = url
        self.size = size
        self.hash = hash
        
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        self.modificationDate = values?.contentModificationDate
        self.creationDate = values?.creationDate
    }
    
    var name: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    var files: [FileItem]
    let size: Int64
    
    var totalSize: Int64 {
        size * Int64(files.count)
    }
    
    var duplicateSize: Int64 {
        size * Int64(max(0, files.count - 1))
    }
}
