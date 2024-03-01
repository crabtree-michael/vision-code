//
//  TreeSitterManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/19/24.
//

import Foundation
import TreeSitterSwift
import SwiftTreeSitter
import CodeEditLanguages
import UIKit

protocol TreeSitterManagerObserver {
    func treeWillChange()
    func treeDidChange(_ tree: MutableTree, with text: String)
}

class TreeSitterManager: TextInputObserver {
    func id() -> String {
        return observerId.uuidString
    }
    
    var mutableTree: MutableTree? {
        return self.tree
    }
    
    let observerId: UUID
    let language: CodeLanguage
    let config: LanguageConfiguration
    let provider: NSTextElementProvider
    
    private let tsLanguage: Language
    private var tree: MutableTree?
    private let parser: Parser
    
    private var observers = [TreeSitterManagerObserver]()
    
    private var changeSizeDelta: Int = 0
    
    
    init(language: CodeLanguage, provider: NSTextElementProvider) throws {
        self.language = language
        self.tsLanguage = language.language!
        self.provider = provider
        
        self.observerId = UUID()
        
        self.config = try LanguageConfiguration(language)
        self.parser = Parser()
        try self.parser.setLanguage(self.config.language)
    }
    
    @objc func textWillChange(in textView: VCTextInputView) {
        for o in observers {
            o.treeWillChange()
        }
    }
    
    func add(observer: TreeSitterManagerObserver) {
        self.observers.append(observer)
    }
    
    func set(text: String) {
        self.tree = parser.parse(text)
        for o in observers {
            o.treeDidChange(self.tree!, with: text)
        }
    }
    
    @objc func textDidChange(in textView: VCTextInputView, oldRange: NSTextRange, newRange: NSTextRange, newValue: String) {
        if let oldStartOffset = oldRange.offset(provider: self.provider),
           let oldEndOffset = oldRange.endOffset(provider: self.provider),
           let newEndOffset = newRange.endOffset(provider: self.provider) {
            let edit = InputEdit(startByte: oldStartOffset * 2,
                                 oldEndByte: oldEndOffset * 2,
                                 newEndByte: newEndOffset * 2,
                                 startPoint: .zero,
                                 oldEndPoint:.zero,
                                 newEndPoint: .zero)
            tree?.edit(edit)
            self.tree = parser.parse(tree: tree, string: newValue)
        }
    }
    
    @objc func textDidFinishChanges(in textView: VCTextInputView, text: String) {
        for observer in observers {
            observer.treeDidChange(tree!, with: text)
        }
    }
}
