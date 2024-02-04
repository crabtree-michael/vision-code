//
//  Highlighter.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/3/24.
//

import Foundation
import UIKit

import SwiftTreeSitter
import TreeSitterGo
import TreeSitterSwift

enum EditorLanguage: String {
    case swift = "Swift"
}

let theme = [
    "variable": UIColor.red,
    "string": UIColor.blue,
    "comment": UIColor.darkGray
]

class RangedAttribute {
    let attribute: NSAttributedString.Key
    let range: NSTextRange
    
    init(attribute: NSAttributedString.Key, range: NSTextRange) {
        self.attribute = attribute
        self.range = range
    }
}

class Highlighter: TextInputObserver {
    let layoutManager: NSTextLayoutManager
    let language: EditorLanguage
    
    private let tsLanguage: Language
    private let parser: Parser
    private var tree: MutableTree?
    private var highlightQuery: Query
    private var provider: NSTextElementProvider
    
    private var allActiveAttributes = [RangedAttribute]()
    
    init(layoutManager: NSTextLayoutManager, provider: NSTextElementProvider, language: EditorLanguage) throws {
        self.layoutManager = layoutManager
        self.language = language
        self.provider = provider
        
        self.tsLanguage = Language(tree_sitter_swift())
        let config = try LanguageConfiguration(language: self.tsLanguage,
                                               name: language.rawValue)
        self.parser = Parser()
        try self.parser.setLanguage(config.language)
        self.highlightQuery = config.queries[.highlights]!
    }
    
    func set(text: String) {
        self.tree = parser.parse(text)
        self.setHighlightsFromTree(text)
    }
    
    @objc func textWillChange(in textView: VCTextInputView) {
        self.removeAllAttributes()
    }
    
    @objc func textDidChange(in textView: VCTextInputView, oldRange: NSTextRange, newRange: NSTextRange, newValue: String) {
//        if let oldStartOffset = oldRange.offset(provider: self.provider),
//           let oldEndOffset = oldRange.endOffset(provider: self.provider),
//           let newEndOffset = newRange.endOffset(provider: self.provider) {
//            let edit = InputEdit(startByte: oldStartOffset,
//                                 oldEndByte: oldEndOffset,
//                                 newEndByte: newEndOffset,
//                                 startPoint: .zero,
//                                 oldEndPoint:.zero,
//                                 newEndPoint: .zero)
//            tree?.edit(edit)
//            
//            
//            self.tree = parser.parse(tree: self.tree, string: newValue)
//            self.setHighlightsFromTree(newValue)
//        }
        self.set(text: newValue)
    }
    
    func setHighlightsFromTree(_ text: String) {
        let cursor = self.highlightQuery.execute(in: self.tree!)
        let highlights = cursor.resolve(with: .init(string: text)).highlights()
        
        var count = 0
        for namedRange in highlights {
            if let color = theme[namedRange.name],
               let start = provider.location?(provider.documentRange.location, offsetBy: namedRange.range.location),
                let end = provider.location?(start, offsetBy: namedRange.range.length),
               let range = NSTextRange(location: start, end: end)
            {
                count += 1
                self.addAttribute(.foregroundColor, value: color, for: range)
            }

            
//            print("\(namedRange.name): \(namedRange.range)")
        }
        
        print("Add \(count)")
    }
    
    private func addAttribute(_ attribute: NSAttributedString.Key, value: Any, for range: NSTextRange) 
    {
        self.allActiveAttributes.append(RangedAttribute(attribute: attribute, range: range))
        layoutManager.addRenderingAttribute(attribute, value: value, for: range)
    }
    
    private func removeAllAttributes() {
        print("Remove \(self.allActiveAttributes.count)")
        for range in self.allActiveAttributes {
            layoutManager.removeRenderingAttribute(range.attribute, for: range.range)
        }

        allActiveAttributes = []
    }
}


extension Point {
    static func zero() -> Point {
        return .init(row: 0, column: 0)
    }
}
