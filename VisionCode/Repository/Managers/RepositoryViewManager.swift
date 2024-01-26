//
//  RepositoryViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class RepositoryViewManager {
    let connection: RCConnection
    let path: String
    let editor: EditorViewManager
    let browser: RepositoryFileBrowserManager
    let state: RepositoryViewState
    
    var didClose: ((RepositoryViewManager) -> ())? = nil
    
    init(path: String, connection: RCConnection) {
        self.connection = connection
        self.editor = EditorViewManager(path: path)
        self.browser = RepositoryFileBrowserManager(path: path)
        self.state = RepositoryViewState(editorState: editor.state, browserState: browser.state)
        self.path = path
        
        self.state.onClose = self.onClose
        
        self.browser.state.onOpenFile = self.openFile
    }
    
    func load() {
        Task {
            do {
                let editorClient = try await self.connection.createSFTPClient()
                self.editor.client = editorClient
                self.editor.loadIfNeeded()
                
                let browserClient = try await self.connection.createSFTPClient()
                self.browser.client = browserClient
                self.browser.load()
            } catch {
                print("Failed to load \(error)")
            }

        }
    }
    
    private func onClose() {
        self.didClose?(self)
        
        Task {
            do {
                try await self.editor.client?.close()
                try await self.browser.client?.close()
            } catch {
                print("Failed to close clients \(error)")
            }
        }
    }
    
    func openFile(_ file:File) {
        self.editor.open(path: file.path)
    }
}
