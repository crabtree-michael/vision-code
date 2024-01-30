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
}
