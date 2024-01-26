//
//  RepositoryFileBrowserManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class RepositoryFileBrowserManager {
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
    
    init(path: String, client: RCSFTPClient? = nil) {
        self.path = path
        self.client = client
        
        self.root = PathNode(file: File(path: path, icon: .folder, isFolder: true), subnodes: [])
        self.state = RepositoryFilesViewState(root: self.root)
        self.loading = false
    }
    
    func load() {
        guard let _ = self.client else {
            return
        }
        guard !self.loading else {
            return
        }
        
        Task {
            do {
                let traverser = BreadthFirstPathTraversal(root: self.root, load: self.get)
                traverser.onNodeLoaded = self.onTraversalLoadedNode
                self.loading = true
                try await traverser.traverse()
                
                DispatchQueue.main.async {
                    self.loading = false
                }
            } catch {
                print("Traversal failed")
            }
        }
    }
    
    func onTraversalLoadedNode(_ traverser: BreadthFirstPathTraversal) {
        self.root = traverser.root
        DispatchQueue.main.async {
            self.state.root = FileCellViewState(node: self.root)
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
                print("Failed to close \(path)")
            }
        }
        return response.viewFiles(path)
    }
}

extension ListResponse {
    func viewFiles(_ root: String) -> [File] {
        return self.files.map { file in
            return File(root as NSString, sftpFile: file)
        }
    }
}
