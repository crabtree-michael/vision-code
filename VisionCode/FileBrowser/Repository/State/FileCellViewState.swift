//
//  FileCellViewState.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

class FileCellViewState: ObservableObject, CustomStringConvertible {
    let file: File
    @Published var loaded: Bool
    @Published var subnodes: [FileCellViewState]
    
    var description: String {
        return "Node at \(file.path) \(loaded ? "loaded" : "not loaded") with \(subnodes.count)"
    }
    
    init(node: PathNode) {
        self.file = node.file
        self.loaded = node.loaded
        self.subnodes = node.subnodes.map({ node in
            return FileCellViewState(node: node)
        })
    }
}
