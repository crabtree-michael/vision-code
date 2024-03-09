//
//  BreadthFirstPathTraversal.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/25/24.
//

import Foundation

class PlannedPathNode {
    let node: PathNode
    let childCount: Int
    
    init(node: PathNode, childCount: Int) {
        self.node = node
        self.childCount = childCount
    }
}

typealias AsyncLoadDirLambda = (String) async throws -> [File]

class BreadthFirstPathTraversal {
    var maxChildCount = 100
    var maxFileSize = 80000
    
    var onNodeLoaded: ((BreadthFirstPathTraversal, PathNode) -> Void)? = nil
    
    var allowLargeFolders = false
    
    let root: PathNode
    private let load: AsyncLoadDirLambda
    
    private var plan: [PathNode]
    private var currentIndex = 0
    
    private var parents: [PlannedPathNode]
    private var currentParentIndex = -1
    
    init(root: PathNode, load: @escaping AsyncLoadDirLambda) {
        self.root = root
        self.plan = [self.root]
        self.currentIndex = 0
        
        self.parents = []
        self.load = load
    }
    
    func traverse() async throws {
        while currentIndex < plan.count {
            let node = plan[currentIndex]
            guard !node.visited else {
                currentIndex += 1
                continue
            }
            
            guard node.file.isFolder else {
                currentIndex += 1
                node.loaded = true
                node.visited = true
                self.appendToParent(node)
                continue
            }
            
            guard node.file.size ?? 0 < maxFileSize else {
                currentIndex += 1
                node.loaded = true
                node.visited = true
                node.skipped = true
                self.appendToParent(node)
                continue
            }
            
            var files = try await self.load(node.file.path)
            
            guard (files.count < maxChildCount || self.allowLargeFolders) else {
                currentIndex += 1
                node.loaded = true
                node.visited = true
                node.skipped = true
                self.appendToParent(node)
                continue
            }
            
            files = files.sorted(by: { a, b in
                b.accessedDate ?? b.modifiedDate ?? Date(timeIntervalSince1970: 0) < b.accessedDate ?? b.modifiedDate ?? Date(timeIntervalSince1970: 0)
            })
            
            var childCount = 0
            for file in files {
                if file.name == "." || file.name == ".." {
                    continue
                }
                plan.append(PathNode(file: file, subnodes: []))
                childCount += 1
            }
            
            
            if childCount > 0 {
                parents.append(PlannedPathNode(node: node, childCount: childCount))
            } else {
                node.loaded = true
            }
               
            if currentParentIndex != -1 {
                self.appendToParent(node)
            } else {
                currentParentIndex += 1
                self.onNodeLoaded?(self, self.root)
            }
            
            node.visited = true
            currentIndex += 1
        }
    }
    
    func appendToParent(_ node: PathNode) {
        let parent = parents[currentParentIndex]
        parent.node.subnodes.append(node)
        if parent.node.subnodes.count == parent.childCount {
            parent.node.loaded = true
            parent.node.sortSubnodes()
            self.onNodeLoaded?(self, parent.node)
            currentParentIndex += 1
        }
    }
}

extension PathNode {
    func sortSubnodes() {
        self.subnodes = self.subnodes.sorted(by: { a, b in
            if a.file.isFolder && !b.file.isFolder {
                return true
            }
            if !a.file.isFolder && b.file.isFolder {
                return false
            }
            return a.file.name < b.file.name
        })
    }
}
