//
//  SimplePairFilter.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/2/24.
//

import Foundation
import TextStory
import TextFormation

public class SimplePairInsertionFilter: Filter {
    public let openString: String
    public let closeString: String

    public init(open: String, close: String) {
        self.openString = open
        self.closeString = close
    }
    
    public func processMutation(_ mutation: TextMutation, in interface: TextInterface, with providers: WhitespaceProviders) -> FilterAction {
        
        guard mutation.string == self.openString else {
            return .none
        }
        
        let nextLocation = mutation.range.max + openString.utf16.count
        let nextCharacterIndex = min(nextLocation, interface.length)
        let nextChar = interface.substring(from: NSRange(mutation.range.max...mutation.range.max))
        if nextChar != self.closeString {
            interface.insertString("\(openString)\(closeString)", at: mutation.range.max)
        }

        interface.selectedRange = NSRange((nextLocation..<nextLocation))
        
        return .discard
    }
}
