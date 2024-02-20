//
//  FileViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation
import CodeEditLanguages

class FileViewState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var content: String = ""
    @Published var error: EditorError? = nil
    @Published var isWriting: Bool = false
    @Published var language: CodeLanguage = .default
    @Published var name: String
    @Published var hasChanges: Bool = false
    @Published var presentUnsavedChangesAlert: Bool = false
    @Published var presentRemoteModifiedAlert: Bool = false
    @Published var showFindInFile: Bool = false
    @Published var tabWidth: TabWidth = .fourTabs
    let file: File
    
    init(file: File) {
        self.file = file
        self.name = file.name
    }
    
    var onSave: (() -> ())? = nil
    
    var onSaveAndClose: VoidLambda? = nil
    var onForceClose: VoidLambda? = nil
    var onOverwriteRemote: VoidLambda? = nil
    var onReloadRemote: VoidLambda? = nil
}
