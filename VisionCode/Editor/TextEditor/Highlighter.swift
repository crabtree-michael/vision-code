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
    var range: NSTextRange
    let value: Any
    
    init(attribute: NSAttributedString.Key, range: NSTextRange, value: Any) {
        self.attribute = attribute
        self.range = range
        self.value = value
    }
}

class Highlighter: TreeSitterManagerObserver {
    let layoutManager: NSTextLayoutManager
    
    var highlightedRange: NSTextRange? = nil
    
    private var highlightQuery: Query
    private var provider: NSTextElementProvider
    private let theme: Theme
    private var treeSitterManager: TreeSitterManager
    private var queryQueue = DispatchQueue(label: "highlight.query")
    
    
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
   }
    
    func resetHighlights(withTree tree: MutableTree, text: String) {
        let cursor = self.highlightQuery.execute(in: tree)
        let highlights = cursor.resolve(with: .init(string: text)).highlights()
        
        for namedRange in highlights {
            self.addAttribute(at: namedRange)
        }
    }
    
    func addAttribute(at namedRange: NamedRange) {
        if
           let start = provider.location?(provider.documentRange.location, offsetBy: namedRange.range.location),
            let end = provider.location?(start, offsetBy: namedRange.range.length),
           let range = NSTextRange(location: start, end: end)
        {
            if let color = theme.color(forHighlight: namedRange.name) {
                self.layoutManager.addRenderingAttribute(.foregroundColor, value: color, for: range)
            }
        }
    }
    
    func highlight(in range: NSTextRange, async: Bool = true) {
        guard let tree = self.treeSitterManager.mutableTree else {
            return
        }
        
        if async {
            self.getHighlights(range, in: tree) { highlights in
                DispatchQueue.main.async {
                    self.highlight(highlights: highlights, in: range)
                }
            }
        } else {
            let highlights = self.highlights(range, in: tree)
            self.highlight(highlights: highlights, in: range)
        }
    }
    
    func highlightViewport(async: Bool = true) {
        if let range = self.layoutManager.textViewportLayoutController.viewportRange {
            self.highlight(in: range, async: async)
        }
    }
    
    func treeDidChange(_ tree: MutableTree, with text: String) {
        self.highlightViewport(async: false)
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
    
    private func highlights(_ range: NSTextRange, in tree: MutableTree) -> [NamedRange] {
        guard
              let startOffset = range.offset(provider: provider),
              let endOffset = range.endOffset(provider: provider) else {
            return []
        }
        
        let cursor = self.highlightQuery.execute(in: tree)
        cursor.setByteRange(range: (UInt32(startOffset*2)..<UInt32(endOffset*2)))
        let highlights = cursor.highlights()
        return highlights
    }
    
    private func getHighlights(_ range: NSTextRange, in tree: MutableTree, completion: @escaping ([NamedRange]) -> ()) {
        self.queryQueue.async {
            completion(self.highlights(range, in: tree))
        }
    }
    
    private func highlight(highlights: [NamedRange], in range: NSTextRange) {
        self.layoutManager.removeRenderingAttribute(.foregroundColor, for: range)
        for namedRange in highlights {
            self.addAttribute(at: namedRange)
        }
        self.layoutManager.textViewportLayoutController.layoutViewport()
        self.highlightedRange = range
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
