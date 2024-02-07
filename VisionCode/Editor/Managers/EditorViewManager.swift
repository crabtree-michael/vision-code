//
//  EditorViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class EditorViewManager: ConnectionUser {
    private let identifier = UUID()
    
    var client: RCSFTPClient? {
        didSet {
            for m in self.openFileManagers {
                m.client = self.client
            }
        }
    }
    let state: EditorViewState
    let path: String
    
    var didClose: ((EditorViewManager) -> ())? = nil
    
    var openFileManagers: [FileViewManager] = [] {
        didSet {
            self.state.openFiles  = openFileManagers.map({ $0.file })
        }
    }
    
    var activeManagerIndex: Int? {
        didSet {
            state.activeIndex = self.activeManagerIndex
            state.activeFileState = self.activeManager?.state
        }
    }
    
    var activeManager: FileViewManager? {
        get {
            guard let index = self.activeManagerIndex else {
                return nil
            }
            
            return self.openFileManagers[index]
        }
    }
    
    var remote: Connection
    
    init(path: String, remote: Connection) {
        self.path = path
        self.state = EditorViewState(title: (path as NSString).lastPathComponent)
        self.remote = remote
        self.state.onFileSelected = self.changeActiveFile
        self.state.onFileClose = self.close
    }
    
    func id() -> String {
        return identifier.uuidString
    }
    
    func load() async  {
        do {
            print("Trying to load client")
            self.client = try await self.remote.createSFTPClient(user: self)
            print("Client loaded successfully")
        } catch {
            print("Failed to load client")
        }
    }
    
    func open(path: String) {
        if let index = openFileManagers.firstIndex(where: {$0.path == path}) {
            self.activeManagerIndex = index
        } else {
            let manager = FileViewManager(path: path, client: client)
            manager.load()
            openFileManagers.append(manager)
            self.activeManagerIndex = openFileManagers.count - 1
        }
    }
    
    func changeActiveFile(file: File) {
        guard let index = openFileManagers.firstIndex(where: {$0.path == file.path}) else {
            print("Attempt to change to file that is not open")
            return
        }
        
        self.activeManagerIndex = index
    }
    
    func close(file: File) {
        guard let index = openFileManagers.firstIndex(where: {$0.path == file.path}) else {
            print("Attempt to close unopened file")
            return
        }
    
        self.openFileManagers.remove(at: index)
        if let activeIndex = state.activeIndex,
        activeIndex >= index {
            var newIndex:Int? = activeIndex - 1
            if newIndex! < 0 {
                if (self.openFileManagers.isEmpty) {
                    newIndex = nil
                } else {
                    newIndex = index
                }
            }
            self.activeManagerIndex = newIndex
        }
    }
    
    func loadIfNeeded() {
        for m in self.openFileManagers {
            if !m.hasAttemptedLoad {
                m.load()
            }
        }
    }
    
    func connectionDidReload(_ connection: Connection) {
        self.remote = connection
        Task {
            await self.load()
        }
    }
}
