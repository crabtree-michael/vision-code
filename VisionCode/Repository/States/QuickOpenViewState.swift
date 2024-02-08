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
    var close: VoidLambda? = nil
    
    init(query: String, files: [File]) {
        self.query = query
        self.files = files
    }
}
