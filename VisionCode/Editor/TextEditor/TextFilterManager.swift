//
//  FormationFilterApplier.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/2/24.
//

import Foundation
import TextFormation
import UIKit
import TextStory

class TextFilterManager: TextViewEditDelegate {
    func id() -> String {
        return self.uniqueID.uuidString
    }
    
    let indenter: TextualIndenter
    var tabWidth: TabWidth {
        didSet {
            self.whiteSpaceProvider = WhitespaceProviders(leadingWhitespace: indenter.substitionProvider(indentationUnit: tabWidth.tabString, width: tabWidth.width)) { _, _ in "" }
            self.backspaceFilter.indentationUnit = tabWidth.tabString
        }
    }
    
    private let uniqueID: UUID
    private let storage: NSTextContentStorage
    private var filter: Filter
    private var whiteSpaceProvider: WhitespaceProviders
    private let backspaceFilter: DeleteWhitespaceFilter
    
    init(width: TabWidth, storage: NSTextContentStorage) {
        self.uniqueID = UUID()
        self.indenter = TextualIndenter(patterns: TextualIndenter.basicPatterns)
        self.storage = storage
        self.tabWidth = width
        self.whiteSpaceProvider = WhitespaceProviders(leadingWhitespace: indenter.substitionProvider(indentationUnit: width.tabString, width: width.width)) { _, _ in "" }
        
        var filters = TextFilterManager.pairFilters()
        let newLineFilter = NewlineProcessingFilter()
        self.backspaceFilter = DeleteWhitespaceFilter(indentationUnit: width.tabString)
        filters.append(contentsOf: [newLineFilter, self.backspaceFilter] as [Filter])
        self.filter = CompositeFilter(filters: filters)
    }
    
    func textViewShouldInsert(_ textView: VCTextInputView, text: String, at location: NSTextLocation) -> Bool {
        let mutation = TextMutation(insert: text, at: location.offset(in: storage), limit: 1)
        let action = filter.processMutation(mutation, in: textView, with: self.whiteSpaceProvider)
        switch (action) {
        case .none, .stop:
            return true
        case .discard:
            return false
        }
    }
    
    func textViewShouldDelete(_ textView: VCTextInputView, range: NSTextRange) -> Bool {
        let mutation = TextMutation(delete: NSRange(range, provider: self.storage, inclusive: true), limit: 1)
        let action = filter.processMutation(mutation, in: textView, with: self.whiteSpaceProvider)
        switch(action) {
        case .none, .stop:
            return true
        case .discard:
            return false
        }
    }
}

extension TextFilterManager {
    static func pairFilters() -> [Filter] {
        let pairs = [
            ("{", "}"),
            ("<", ">"),
            ("(", ")"),
            ("[", "]")
        ]
        
        var result = [Filter]()
        for p in pairs {
            result.append(StandardOpenPairFilter(open: p.0, close: p.1))
            result.append(DeleteBlockCloseFilter(open: p.0, close: p.1))
        }
        
        let simplePairs = [
            ("\"", "\""),
            ("'", "'")
        ]
        for p in simplePairs {
            result.append(SimplePairInsertionFilter(open: p.0, close: p.1))
            result.append(DeleteBlockCloseFilter(open: p.0, close: p.1))
        }
        
        return result
    }
}

public extension NSTextLocation {
    func offset(in storage: NSTextContentStorage) -> Int {
        return storage.offset(from: storage.documentRange.location, to: self)
    }
}
