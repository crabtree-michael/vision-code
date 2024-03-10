//
//  RepositoryFileBrowserManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class RepositoryFileBrowserManager: ConnectionUser {
    private let identifier: UUID
    var client: RCSFTPClient?
    let state: RepositoryFilesViewState
    let path: String
    var loading: Bool {
        didSet {
            DispatchQueue.main.async {
                self.state.isLoading = self.loading
            }
        }
    }
    
    var root: PathNode
    
    var remote: Connection
    
    let trieRoot = TrieNode<String, PathNode>()
    
    var open: FileLambda? = nil
    
    var largeFolder: File? = nil
    
    init(path: String, remote: Connection) {
        self.path = path
        
        self.root = PathNode(file: File(path: path, icon: .folder, isFolder: true), subnodes: [])
        self.state = RepositoryFilesViewState(root: self.root, connectionState: remote.state)
        self.loading = false
        self.remote = remote
        self.identifier = UUID()
        
        self.state.refreshDirectory = { folder in
            self.reload(folder: folder, allowLargeFolders: false)
        }
        self.state.createFile = self.createFile
        self.state.createFolder = self.createFolder
        self.state.onOpenFile = self.onOpen
        self.state.loadLargeFolder = self.loadLargeFolder
    }
    
    func id() -> String {
        return identifier.uuidString + "-repository-manager"
    }
    
    func load(traverse: Bool = true) async {
        do {
            self.client = try await self.remote.createSFTPClient(user: self)
            guard let _ = self.client else {
                return
            }
            guard !self.loading && traverse else {
                return
            }
            
            try await self.load(node: self.root)
        } catch {
            DispatchQueue.main.async {
                self.state.error = error
                self.state.showErrorAlert = true
            }
        }
    }
    
    func reload(folder: File, allowLargeFolders: Bool = false) {
        guard folder.isFolder else {
            return
        }
        
        self.state.root.update(subnode: folder.path, loaded: false, subnodes: [])
        
        Task {
            do {
                let node = PathNode(file: folder, subnodes: [])
                try await self.load(node: node, allowLargeFolders: allowLargeFolders)
            } catch {
                print("Failed to load \(error)")
            }
        }
    }
    
    func load(node: PathNode, allowLargeFolders: Bool = false) async throws {
        let isRoot = node.file.path == self.root.file.path
        if isRoot {
            self.loading = true
        }
        
        let traverser = BreadthFirstPathTraversal(root: node, load: self.get)
        traverser.allowLargeFolders = allowLargeFolders
        traverser.onNodeLoaded = self.onTraversalLoadedNode
        try await traverser.traverse()
        if isRoot {
            self.loading = false
        }
    }
    
    func onTraversalLoadedNode(_ traverser: BreadthFirstPathTraversal, node: PathNode) {
        self.update(node: node)
    }
    
    private func update(node: PathNode) {
        let view = FileCellViewState(node: node)
        DispatchQueue.main.async {
            if view.file.path == self.path {
                self.state.root = view
                return
            }
            self.state.root.update(subnode: view.file.path, loaded: node.loaded, subnodes: view.subnodes)
        }
        
        var oldNode: PathNode?
        if node.file.path == self.path {
            oldNode = self.root
            self.root = node
            
        } else {
            oldNode = self.root.update(node: node)
        }
        
        if let oldNode = oldNode {
            self.removeNodeFromTrie(node: oldNode)
        }
        
        for n in node.subnodes {
            self.trieRoot.insert(value: n, for: n.file.name)
        }
    }
    
    func add(node: PathNode) {
        guard let parent = self.root.add(node: node) else {
            return
        }
        parent.sortSubnodes()
        self.update(node: parent)
    }
    
    func createFile(parent: File, name: String) {
        guard let client = client, !name.isEmpty else {
            return
        }
        
        let fullPath = parent.path + "/" + name
        let newNode = PathNode(file: File(path: fullPath), subnodes: [], loaded: true)
        Task {
            do {
                let r = try await client.open(file: fullPath, permissions: [.CREAT])
                self.add(node: newNode)
                try await client.close(response: r)
            } catch {
                self.state.error = error
            }
        }
    }
    
    func createFolder(parent: File, name: String) {
        guard let client = client, !name.isEmpty else {
            return
        }
        
        let fullPath = parent.path + "/" + name
        let newNode = PathNode(file: File(path: fullPath, isFolder: true), subnodes: [], loaded: true)
        Task {
            do {
                try await client.makeDirectory(at: fullPath)
                self.add(node: newNode)
            } catch {
                self.state.error = error
            }
        }
    }
    
    func onOpen(file: File) {
        if file.isFolder {
            self.largeFolder = file
            self.state.showLargeFolderWarning = true
        } else {
            self.open?(file)
        }
    }
    
    func loadLargeFolder() {
        state.showLargeFolderWarning = false
        guard let folder = self.largeFolder else {
            return
        }
        
        self.reload(folder: folder, allowLargeFolders: true)
    }
    
    private func removeNodeFromTrie(node: PathNode) {
        self.trieRoot.remove(value: node, for: node.file.name)
        for n in node.subnodes {
            self.removeNodeFromTrie(node: n)
        }
    }
    
    private func get(path: String) async throws -> [File] {
        guard let client = self.client else {
            throw EditorError.encodingFailed
        }
        
        var response = try await client.list(path: path)
        let shouldClose = response.hasMore
        while response.hasMore {
            response = try await client.append(to: response)
        }
        if shouldClose {
            do {
                try await client.close(response: response)
            } catch {
                print("Failed to close \(path): \(error)")
            }
        }
        return response.viewFiles(path)
    }
    
    func connectionDidReload(_ connection: Connection) {
        DispatchQueue.main.async {
            print("Set connection state to \(connection.state.displayMessage())")
            self.state.connectionState = connection.state
        }
       
        self.remote = connection
        Task {
            await self.load(traverse: false)
        }
    }
    
    func files(withPrefix prefix: String) -> [File] {
        return trieRoot.retrieve(key: prefix)
            .filter { !$0.file.isFolder }
            .map { $0.file }
    }
    
    private func files(withPrefix prefix: String, in node: PathNode) -> [File] {
        var result: [File] = []
        
        if node.file.name.lowercased().hasPrefix(prefix.lowercased()) && !node.file.isFolder {
            result.append(node.file)
        }
        
        for subnode in node.subnodes {
            result.append(contentsOf: files(withPrefix: prefix, in: subnode))
        }
        
        return result
    }
}

extension ListResponse {
    func viewFiles(_ root: String) -> [File] {
        return self.files.map { file in
            return File(root as NSString, sftpFile: file)
        }
    }
}
