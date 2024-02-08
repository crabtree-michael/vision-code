//
//  RepositoryViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore
import Combine

class RepositoryEditorViewManager {
    let remote: Connection
    let path: String
    let editor: EditorViewManager
    let browser: RepositoryFileBrowserManager
    let terminal: TerminalManager
    let state: RepositoryEditorViewState
    
    var didClose: ((RepositoryEditorViewManager) -> ())? = nil
    
    var tasks = [AnyCancellable]()
    
    init(path: String, connection: Connection) {
        self.remote = connection
        self.editor = EditorViewManager(path: path, remote: connection)
        self.browser = RepositoryFileBrowserManager(path: path, remote: connection)

        self.terminal = TerminalManager(connection: connection)
        
        self.state = RepositoryEditorViewState(editorState: editor.state, browserState: browser.state, terminalState: self.terminal.state)
        self.path = path
        
        self.state.onClose = self.onClose
        
        self.browser.state.onOpenFile = self.openFile
        
        self.editor.state.onQuickOpen = self.openQuickOpen
        self.state.closeQuickOpen = self.closeQuickOpen
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
    
    func openQuickOpen() {
        self.state.quickOpenSate = QuickOpenViewState(query: "", files: [])
        self.state.quickOpenSate?.onFileSelected = { file in
            self.openFile(file)
            self.closeQuickOpen()
        }
        self.state.quickOpenSate?.close = self.closeQuickOpen
        self.state.quickOpenSate?.$query.sink(receiveValue: { query in
            if query != "" {
                self.quickOpenSearch(query: query)
            } else {
                self.clearQuickOpen()
            }
        }).store(in: &self.tasks)
    }
    
    func closeQuickOpen() {
        self.state.quickOpenSate = nil
    }
    
    func quickOpenSearch(query: String) {
        let files = self.browser.files(withPrefix: query)
        self.state.quickOpenSate?.files = files
    }
    
    func clearQuickOpen() {
        self.state.quickOpenSate?.files = []
    }
}
