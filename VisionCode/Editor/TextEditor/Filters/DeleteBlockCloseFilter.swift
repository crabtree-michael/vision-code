//
//  DeleteBlockCloseFilter.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/2/24.
//

import Foundation
import TextFormation
import TextStory

public class DeleteBlockCloseFilter {
    public let openString: String
    public let closeString: String

    public init(open: String, close: String) {
        self.openString = open
        self.closeString = close
    }
}

extension DeleteBlockCloseFilter: Filter {
    public func processMutation(_ mutation: TextMutation, in interface: TextInterface, with providers: WhitespaceProviders) -> FilterAction {
        guard mutation.string == "" && mutation.range.length > 0 else {
            return .none
        }

        guard interface.substring(from: mutation.range) == openString else {
            return .none
        }
        
        let index = interface.findNextOccurrenceOfCharacter(
            in: .whitespacesAndNewlines.inverted,
            from: mutation.range.upperBound) ?? mutation.range.max

        let closeRange = NSRange(location: index, length: closeString.utf16.count)

        guard interface.substring(from: closeRange) == closeString else {
            return .none
        }

        let deleteRange = NSRange(location: mutation.range.location, length: closeRange.max - mutation.range.location)
        interface.applyMutation(TextMutation(delete: deleteRange, limit: interface.length))

        return .discard
    }
}
