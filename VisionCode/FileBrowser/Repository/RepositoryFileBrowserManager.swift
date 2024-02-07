//
//  RepositoryFileBrowserManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class RepositoryFileBrowserManager: ConnectionUser {
    private let identifier = UUID()
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
    
    init(path: String, remote: Connection) {
        self.path = path
        
        self.root = PathNode(file: File(path: path, icon: .folder, isFolder: true), subnodes: [])
        self.state = RepositoryFilesViewState(root: self.root, connectionState: remote.state)
        self.loading = false
        self.remote = remote
    }
    
    func id() -> String {
        return identifier.uuidString
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
            
            let traverser = BreadthFirstPathTraversal(root: self.root, load: self.get)
            traverser.onNodeLoaded = self.onTraversalLoadedNode
            self.loading = true
            try await traverser.traverse()
            
            DispatchQueue.main.async {
                self.loading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.state.error = error
            }
        }

    }
    
    func onTraversalLoadedNode(_ traverser: BreadthFirstPathTraversal) {
        self.root = traverser.root
//        let r = self.root.copy() as! PathNode
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
}

extension ListResponse {
    func viewFiles(_ root: String) -> [File] {
        return self.files.map { file in
            return File(root as NSString, sftpFile: file)
        }
    }
}
