//
//  QuickOpenViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/8/24.
//

import Foundation

class QuickOpenViewState: ObservableObject {
    @Published var query: String
    @Published var files: [File]
    
    var onFileSelected: FileLambda? = nil
    
    init(query: String, files: [File]) {
        self.query = query
        self.files = files
    }
}
