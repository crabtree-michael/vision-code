//
//  RepositoryViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore

class RepositoryEditorViewManager {
    let remote: Connection
    let path: String
    let editor: EditorViewManager
    let browser: RepositoryFileBrowserManager
    let terminal: TerminalManager
    let state: RepositoryEditorViewState
    
    var didClose: ((RepositoryEditorViewManager) -> ())? = nil
    
    init(path: String, connection: Connection) {
        self.remote = connection
        self.editor = EditorViewManager(path: path, remote: connection)
        self.browser = RepositoryFileBrowserManager(path: path, remote: connection)

        self.terminal = TerminalManager(connection: connection)
        
        self.state = RepositoryEditorViewState(editorState: editor.state, browserState: browser.state, terminalState: self.terminal.state)
        self.path = path
        
        self.state.onClose = self.onClose
        
        self.browser.state.onOpenFile = self.openFile
    }
    
    func load() {
        Task {
            await self.editor.load()
        }
        Task {
            await self.browser.load()
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
