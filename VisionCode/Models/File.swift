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
    
    var modifiedDate: Date?
    var accessedDate : Date?
    
    var pathComponents: [String] {
        return (self.path as NSString).pathComponents
    }
    
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
        if let aTime = sftpFile.attributes.atime {
            self.accessedDate = Date.init(timeIntervalSince1970: TimeInterval(aTime))
        }
        if let mTime = sftpFile.attributes.mtime {
            self.modifiedDate = Date.init(timeIntervalSince1970: TimeInterval(mTime))
        }
    }
}

class PathNode: Hashable {
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
    
    static func == (lhs: PathNode, rhs: PathNode) -> Bool {
        return lhs.file.path == rhs.file.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(file.path)
    }
    
    func copy() -> PathNode {
        var subnodes: [PathNode] = []
        for s in self.subnodes {
            subnodes.append(s.copy())
        }
        
        let c = PathNode(file: self.file, subnodes: subnodes, loaded: self.loaded)
        c.visited = self.visited
        c.loaded = self.loaded
        c.skipped = self.skipped
        return c
    }
    
    func update(node: PathNode) -> PathNode? {
        guard let parentNode = self.findParent(path: node.file.path, currentComponentIndex: self.file.pathComponents.count),
              let index = parentNode.subnodes.firstIndex(where: { $0.file.path == node.file.path }) else {
            return nil
        }
        let oldNode = parentNode.subnodes[index]
        parentNode.subnodes[index] = node
        
        return oldNode
    }
    
    func add(node: PathNode) -> PathNode? {
        guard let parentNode = self.findParent(path: node.file.path, currentComponentIndex: self.file.pathComponents.count) else {
            return nil
        }
        
        if let _ = parentNode.subnodes.firstIndex(where: { $0.file.name == node.file.name }) {
            return nil
        }

        parentNode.subnodes.append(node)
        return parentNode
    }
    
    private func findParent(path: String, currentComponentIndex: Int) -> PathNode? {
        let components = (path as NSString).pathComponents
        guard currentComponentIndex < components.count else {
            return nil
        }
        
        let component = components[currentComponentIndex]
        
        if currentComponentIndex > 0 &&
            currentComponentIndex == components.count - 1 &&
            self.file.name == components[currentComponentIndex - 1] {
            return self
        }
        
        for node in self.subnodes {
            if node.file.path == path {
                return self
            }
            if node.file.name == component {
                return node.findParent(path: path, currentComponentIndex: currentComponentIndex + 1)
            }
        }
        
        return nil
    }
}
