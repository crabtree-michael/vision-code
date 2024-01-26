//
//  FolderViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

class FolderViewState: ObservableObject {
    var name: String
    @Published var files: [File]? = nil
    @Published var isLoading = true
    @Published var encounteredError: Error? = nil
    var onClose: (() -> ())? = nil
    var onOpenFile: ((File) -> ())? = nil
    var onReturnHome: (() -> ())? = nil
    
    init(name: String) {
        self.name = name
    }
}
