//
//  RepositoryViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

class RepositoryViewState: ObservableObject {
    let editorState: EditorViewState
    let browserState: RepositoryFilesViewState
    
    var onClose: VoidLambda? = nil
    
    init(editorState: EditorViewState, browserState: RepositoryFilesViewState) {
        self.editorState = editorState
        self.browserState = browserState
    }
}
