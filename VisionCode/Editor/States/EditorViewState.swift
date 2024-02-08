//
//  EditorViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

class EditorViewState: ObservableObject {
    var title: String
    @Published var activeIndex: Int? = nil
    @Published var openFiles: [File] = []
    @Published var openFileStates: [FileViewState] = []
    var onFileSelected: FileLambda? = nil
    var onFileClose: FileLambda? = nil
    var onClose: VoidLambda? = nil
    var onQuickOpen: VoidLambda? = nil
    
    init(title: String) {
        self.title = title
    }
}
