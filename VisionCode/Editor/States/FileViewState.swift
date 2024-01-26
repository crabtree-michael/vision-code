//
//  FileViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

class FileViewState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var content: String = ""
    @Published var error: EditorError? = nil
    @Published var isWriting: Bool = false
    
    var onSave: (() -> ())? = nil
}
