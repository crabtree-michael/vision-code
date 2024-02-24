//
//  Highlighter.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/3/24.
//

import Foundation
import UIKit

import SwiftTreeSitter
import TreeSitterSwift
import CodeEditLanguages

class RangedAttribute {
    let attribute: NSAttributedString.Key
    let range: NSTextRange
    
    init(attribute: NSAttributedString.Key, range: NSTextRange) {
        self.attribute = attribute
        self.range = range
    }
}

class Highlighter: TreeSitterManagerObserver {
    let layoutManager: NSTextLayoutManager
    
    private var highlightQuery: Query
    private var provider: NSTextElementProvider
    
    private let theme: Theme
    
    private var allActiveAttributes = [RangedAttribute]()
    private var treeSitterManager: TreeSitterManager
    
    
    init(theme: Theme,
        treeSitterManager: TreeSitterManager,
         layoutManager: NSTextLayoutManager,
         provider: NSTextElementProvider) throws {
        self.theme = theme
        self.layoutManager = layoutManager
        self.provider = provider
        self.highlightQuery = treeSitterManager.config.queries[.highlights]!
        
        self.treeSitterManager = treeSitterManager
        self.treeSitterManager.add(observer: self)
    }
    
   func treeWillChange() {
        self.removeAllAttributes()
    }
    
    func treeDidChange(_ tree: MutableTree, with text: String) {
        let cursor = self.highlightQuery.execute(in: tree)
        let highlights = cursor.resolve(with: .init(string: text)).highlights()
        
        for namedRange in highlights {
            if
               let start = provider.location?(provider.documentRange.location, offsetBy: namedRange.range.location),
                let end = provider.location?(start, offsetBy: namedRange.range.length),
               let range = NSTextRange(location: start, end: end)
            {
                if let color = theme.color(forHighlight: namedRange.name) {
                    self.addAttribute(.foregroundColor, value: color, for: range)
                }
            }
        }
    }
    
    func highlightName(for range: NSTextRange, in text: String) -> String? {
        guard let tree = treeSitterManager.mutableTree else {
            return nil
        }
        
        let cursor = self.highlightQuery.execute(in: tree)
        let highlights = cursor.resolve(with: .init(string: text)).highlights()
        
        for namedRange in highlights {
            if
               let start = provider.location?(provider.documentRange.location, offsetBy: namedRange.range.location),
                let end = provider.location?(start, offsetBy: namedRange.range.length),
               let highlightRange = NSTextRange(location: start, end: end),
               highlightRange.intersects(range)
            {
                return namedRange.name
            }
        }

        return nil
    }
    
    func tokenRange(at index: NSTextLocation) {
    }
    
    private func addAttribute(_ attribute: NSAttributedString.Key, value: Any, for range: NSTextRange) 
    {
        self.allActiveAttributes.append(RangedAttribute(attribute: attribute, range: range))
        layoutManager.addRenderingAttribute(attribute, value: value, for: range)
    }
    
    private func removeAllAttributes() {
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

extension LanguageConfiguration {
    init(language: Language, name: String) throws {
        guard let bundlePath = Bundle.main.path(forResource: "TreeSitterSwift_TreeSitterSwift", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath) else {
            throw CommonError.objectNotFound
        }
        
        try self.init(language, name: name, bundle: bundle)
    }
    
    init(_ l: Language, name: String, bundle:Bundle) throws {
        var queries: [SwiftTreeSitter.Query.Definition: SwiftTreeSitter.Query] = [:]
        if let queriesFolderPath = bundle.path(forResource: "queries", ofType: nil) {
            let queriesFiles = try FileManager.default.contentsOfDirectory(atPath: queriesFolderPath)
            
            for file in queriesFiles {
                let url = URL(string: queriesFolderPath)!.appending(path: file)
                if let data = FileManager.default.contents(atPath: url.absoluteString) {
                    let query = try Query(language: l, data: data)
                    
                    switch(file) {
                    case "highlights.scm":
                        queries[.highlights] = query
                    case "locals.scm":
                        queries[.locals] = query
                    case "injections.scm":
                        queries[.injections] = query
                    default: break
                    }
                }

            }
        }
        
        self.init(l, name: name, queries: queries)
    }
    
    init(_ language: CodeLanguage) throws {
        var queries: [SwiftTreeSitter.Query.Definition: SwiftTreeSitter.Query] = [:]
        
        guard let l = language.language else {
            throw CommonError.objectNotFound
        }
        
        let queryTypes: [Query.Definition] = [.highlights, .injections, .locals]
        for t in queryTypes {
            if let data = FileManager.default.contents(atPath: language.url(for: t)) {
                queries[t] = try Query(language: l, data: data)
            }
        }
        
        self.init(l, name: language.tsName, queries: queries)
    }
}

extension CodeLanguage {
    func url(for query: Query.Definition) -> String {
        return Bundle.main.bundlePath.appending("/CodeEditLanguages_CodeEditLanguages.bundle/Languages/tree-sitter-\(self.tsName)/\(query.name).scm")
    }
}

extension NSRange {
    func textRange(from provider: NSTextElementProvider) -> NSTextRange? {
        guard let beginning = provider.location?(provider.documentRange.location, offsetBy: self.lowerBound),
              let ending = provider.location?(provider.documentRange.location, offsetBy: self.upperBound) else {
            return nil
        }
        
        return .init(location: beginning, end: ending)
    }
}
