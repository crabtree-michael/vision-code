//
//  RepositoryViewManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import VCRemoteCommandCore
import Combine
import RealmSwift

class RepositoryEditorViewManager {
    let connectionManager: ConnectionManager
    var connection: Connection? = nil
    let path: String
    var editor: EditorViewManager?
    var browser: RepositoryFileBrowserManager?
    var terminal: TerminalManager?
    let state: RepositoryEditorViewState
    var hostId: ObjectId? = nil
    
    var didClose: ((RepositoryEditorViewManager) -> ())? = nil
    var onCloseEditor: VoidLambda? = nil
    
    var tasks = [AnyCancellable]()
    
    init(path: String, connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
        self.path = path
        self.state = RepositoryEditorViewState(connectionState: .connecting, editorState: nil, browserState: nil, terminalState: nil)
        
        self.state.onClose = self.onClose
        self.state.closeQuickOpen = self.closeQuickOpen
        self.state.onDismissedError = {
            if self.browser == nil && self.editor == nil {
                self.onCloseEditor?()
            }
        }
        
        self.state.$scenePhase
            .sink { [weak self] phase in
            Task { @MainActor [weak self] in
                if let connection = self?.connection,
                   let id = self?.hostId,
                   phase == .active &&
                    (connection.status != .connecting || connection.status != .connected) {
                    self?.connectionManager.reload(id: id)
                }
            }
        }
        .store(in: &tasks)
    }
    
    @MainActor func load(hostID: ObjectId) {
        self.hostId = hostID
        let connection = self.connectionManager.connection(for: hostID)
        connection.state.$status.sink { [weak self] state in
            guard let self = self else {
                return
            }
            
            switch(state) {
            case .connected:
                self.setupManagers(withConnection: connection)
            case .notStarted:
                if self.state.scenePhase == .active {
                    self.connectionManager.reload(id: hostID)
                }
            case .connecting:
                break
            case .failed(let error):
                self.state.error = error
            }
        }.store(in: &tasks)
    }
    
    private func onClose() {
        self.didClose?(self)
    }
    
    func openFile(_ file:File) {
        self.editor?.open(path: file.path)
    }
    
    func cleanUp() {
        Task {
            do {
                try await self.editor?.client?.close()
                try await self.browser?.client?.close()
            } catch {
                print("Failed to close clients \(error)")
            }
        }
    }
    
    func openQuickOpen() {
        guard self.state.quickOpenSate == nil else {
            self.closeQuickOpen()
            return
        }
        
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
        guard let files = self.browser?.files(withPrefix: query) else {
            return
        }
        self.state.quickOpenSate?.files = files
    }
    
    func clearQuickOpen() {
        self.state.quickOpenSate?.files = []
    }
    
    private func setupManagers(withConnection connection: Connection) {
        if self.editor == nil || self.browser == nil || self.terminal == nil {
            self.editor = EditorViewManager(path: path, remote: connection)
            self.browser = RepositoryFileBrowserManager(path: path, remote: connection)
            self.terminal = TerminalManager(connection: connection, directory: path)
            
            self.state.editorState = editor?.state
            self.state.browserState = browser?.state
            self.state.terminalState = terminal?.state
            
            self.browser?.open = self.openFile
            self.browser?.state.closeProject = {
                self.onCloseEditor?()
            }
            
            self.editor?.state.onQuickOpen = self.openQuickOpen
        } else {
            self.editor?.remote = connection
            self.browser?.remote = connection
            self.terminal?.state.connection = connection
        }
        
        Task {
            await self.editor?.load()
        }
        Task {
            await self.browser?.load()
        }
    }
}
