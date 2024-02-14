//
//  TrieNode.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/8/24.
//

import Foundation

public class TrieNode<Key, Element> where Key: StringProtocol {
    var branches = [Character: TrieNode<Key, Element>]()
    var contents = [Element]()
    
    func insert(value: Element, for key: Key) {
        let key = Substring(key.lowercased())
        return self.rInsert(value: value, for: key)
    }
    
    private func rInsert(value: Element, for key: Substring) {
        contents.append(value)
        
        guard let c = key.first else {
            return
        }
        
        let substring = key.dropFirst()
        var branch = branches[c]
        if branch == nil {
            branch = TrieNode()
            branches[c] = branch
        }
        branch!.rInsert(value: value, for: substring)
    }
    
    func retrieve(key: Key) -> [Element] {
        let key = Substring(key.lowercased())
        return self.rRetrieve(key: key)
    }
    
    private func rRetrieve(key: Substring) -> [Element] {
        guard let c = key.first else {
            return self.contents
        }
        
        guard let branch = branches[c] else {
            print("no branch for \(c)")
            return []
        }
        
        return branch.rRetrieve(key: key.dropFirst())
    }
}
