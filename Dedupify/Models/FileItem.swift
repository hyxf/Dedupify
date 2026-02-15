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
    var isSelected: Bool = false
    
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
