//
//  File.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

enum FileIcon: String {
    case file = "doc.fill"
    case folder = "folder.fill"
}

struct File {
    var path: String
    var icon: FileIcon = .file
    var name: String {
        get {
            (self.path as NSString).lastPathComponent
        }
    }
    var isFolder: Bool = false
    var content: String = ""
    var size: Int? = nil
    
    init(path: String, icon: FileIcon = .file, isFolder: Bool = false, content: String = "") {
        self.path = path
        self.icon = isFolder ? .folder : .file
        self.isFolder = isFolder
        self.content = content
    }
    
    init(_ root: NSString, sftpFile: VCRemoteCommandCore.File) {
        self.path = root.appendingPathComponent(sftpFile.filename)
        self.icon = sftpFile.isDirectory ? .folder : .file
        self.isFolder = sftpFile.isDirectory
        if let size = sftpFile.attributes.size {
            self.size = Int(size)
        }
    }
}

class PathNode {
    let file: File
    var subnodes: [PathNode] = []
    var visited: Bool = false
    var loaded: Bool = false
    var skipped: Bool = false
    
    init(file: File, subnodes: [PathNode], loaded: Bool = false) {
        self.file = file
        self.subnodes = subnodes
        self.loaded = loaded
    }
}
