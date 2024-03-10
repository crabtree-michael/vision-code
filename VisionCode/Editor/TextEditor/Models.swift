//
//  Models.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/29/24.
//

import Foundation
import UIKit

class TextPosition: UITextPosition {
    var location: Int
    
    func nsTextLocation(in provider: NSTextElementProvider) -> NSTextLocation? {
        return provider.location?(provider.documentRange.location, offsetBy: location)
    }

    init(location: Int) {
        self.location = location
    }
    
    init(location: NSTextLocation, provider: NSTextElementProvider) {
        self.location = provider.offset?(from: provider.documentRange.location, to: location) ?? 0
    }
}


class TextRange: UITextRange {
    override var start: TextPosition {
        get {
            _start
        }
    }
    override var end: TextPosition {
        get {
            _end
        }
    }
    
    let _start: TextPosition
    let _end: TextPosition

    override var isEmpty: Bool {
        return start.location == end.location
    }

    init(start: TextPosition, end: TextPosition) {
        self._start = start
        self._end = end
    }
    
    init(range: NSTextRange, provider: NSTextElementProvider) {
        self._start = TextPosition(location: range.location, provider: provider)
        self._end = TextPosition(location: range.endLocation, provider: provider)
    }
    
    func nsTextRange(in provider: NSTextElementProvider) -> NSTextRange? {
        guard let start = start.nsTextLocation(in: provider),
              let end = end.nsTextLocation(in: provider) else {
            return nil
        }
        return NSTextRange(location: start, end: end)
    }
}
