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
    @Published var newFileName: String = ""
    
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
    
    func update(subnode path: String, loaded: Bool, subnodes: [FileCellViewState]) {
        guard let node = self.find(path: path, currentComponentIndex: self.file.pathComponents.count) else {
            return
        }
        
        node.loaded = loaded
        node.subnodes = subnodes
    }
    
    private func find(path: String, currentComponentIndex: Int) -> FileCellViewState? {
        if self.file.path == path {
            return self
        }
        
        let component = (path as NSString).pathComponents[currentComponentIndex]
        
        for node in self.subnodes {
            if node.file.name == component {
                return node.find(path: path, currentComponentIndex: currentComponentIndex + 1)
            }
        }
        return nil
    }
}
