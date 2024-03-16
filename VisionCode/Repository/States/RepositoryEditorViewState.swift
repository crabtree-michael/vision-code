//
//  RepositoryViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

class RepositoryEditorViewState: ObservableObject {
    let connectionState: ConnectionState
    @Published var editorState: EditorViewState?
    @Published var browserState: RepositoryFilesViewState?
    @Published var terminalState: TerminalViewState?
    
    @Published var quickOpenSate: QuickOpenViewState? = nil
    
    @Published var error: Error? = nil
    
    @Published var scenePhase: ScenePhase
    
    var closeQuickOpen: VoidLambda? = nil
    var onClose: VoidLambda? = nil
    var onDismissedError: VoidLambda? = nil
    
    init(connectionState: ConnectionState, editorState: EditorViewState?, browserState: RepositoryFilesViewState?, terminalState: TerminalViewState?) {
        self.editorState = editorState
        self.browserState = browserState
        self.terminalState = terminalState
        self.connectionState = connectionState
        self.scenePhase = .active
    }
}
