//
//  RepositoryViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class RepositoryEditorViewManager {
    let connection: RCConnection
    let path: String
    let editor: EditorViewManager
    let browser: RepositoryFileBrowserManager
    let terminal: TerminalManager
    let state: RepositoryEditorViewState
    
    var didClose: ((RepositoryEditorViewManager) -> ())? = nil
    
    init(path: String, connection: RCConnection) {
        self.connection = connection
        self.editor = EditorViewManager(path: path)
        self.browser = RepositoryFileBrowserManager(path: path)

        self.terminal = TerminalManager(title: (path as NSString).lastPathComponent, connection: connection)
        self.terminal.state.showTitle = false
        
        self.state = RepositoryEditorViewState(editorState: editor.state, browserState: browser.state, terminalState: self.terminal.state)
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
                
                await self.terminal.connect()
            } catch {
                print("Failed to load \(error)")
            }

        }
    }
    
    private func onClose() {
        self.didClose?(self)
    }
    
    func openFile(_ file:File) {
        self.editor.open(path: file.path)
    }
    
    func cleanUp() {
        Task {
            do {
                try await self.editor.client?.close()
                try await self.browser.client?.close()
            } catch {
                print("Failed to close clients \(error)")
            }
        }
    }
}
