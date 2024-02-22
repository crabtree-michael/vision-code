//
//  TrieNode.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/8/24.
//

import Foundation

public class TrieNode<Key, Element> where Key: StringProtocol, Element: Hashable {
    var branches = [Character: TrieNode<Key, Element>]()
    var contents = Set<Element>()
    
    func insert(value: Element, for key: Key) {
        let key = Substring(key.lowercased())
        self.navigate(value: value, for: key, createBranches: true) { trie in
            trie.contents.insert(value)
        }
    }
    
    func remove(value: Element, for key: Key) {
        let key = Substring(key.lowercased())
        self.navigate(value: value, for: key) { trie in
            trie.contents.remove(value)
        }
    }
    
    private func navigate(value: Element, for key: Substring, createBranches: Bool = false, lambda: (TrieNode<Key, Element>) -> ()) {
        lambda(self)
        
        guard let c = key.first else {
            return
        }
        
        let substring = key.dropFirst()
        var branch = branches[c]
        if branch == nil && createBranches {
            branch = TrieNode()
            branches[c] = branch
        }
        branch?.navigate(value: value, 
                         for: substring,
                         createBranches: createBranches,
                         lambda: lambda)
    }
    
    func retrieve(key: Key) -> [Element] {
        let key = Substring(key.lowercased())
        return self.rRetrieve(key: key)
    }
    
    private func rRetrieve(key: Substring) -> [Element] {
        guard let c = key.first else {
            return Array(self.contents)
        }
        
        guard let branch = branches[c] else {
            return []
        }
        
        return branch.rRetrieve(key: key.dropFirst())
    }
}
