//
//  RepositoryFilesViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import SwiftUI

class RepositoryFilesViewState: ObservableObject {
    @Published var root: FileCellViewState
    @Published var isLoading: Bool = true
    
    var onOpenFile: FileLambda? = nil
    
    init(root: PathNode) {
        self.root = FileCellViewState(node: root)
    }
}
