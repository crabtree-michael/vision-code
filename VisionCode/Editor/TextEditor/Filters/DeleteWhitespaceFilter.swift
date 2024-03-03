//
//  DeleteWhitespaceFilter.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/2/24.
//

import Foundation
import TextStory
import TextFormation

/// Filter for quickly deleting indent whitespace
class DeleteWhitespaceFilter: Filter {
    var indentationUnit: String
    
    init(indentationUnit: String) {
        self.indentationUnit = indentationUnit
    }

    func processMutation(_ mutation: TextMutation, in interface: TextInterface, with providers: TextFormation.WhitespaceProviders) -> FilterAction {
        guard mutation.string == "" && mutation.range.length == 1 && indentationUnit.count > 1 else {
            return .none
        }

        // Walk backwards from the mutation, grabbing as much whitespace as possible
        guard let preceedingNonWhitespace = interface.findPrecedingOccurrenceOfCharacter(
            in: CharacterSet.whitespaces.inverted,
            from: mutation.range.max
        ) else {
            return .none
        }

        let length = mutation.range.max - preceedingNonWhitespace
        let numberOfExtraSpaces = length % indentationUnit.count

        if numberOfExtraSpaces == 0 && length >= indentationUnit.count {
            interface.applyMutation(
                TextMutation(delete: NSRange(location: mutation.range.max - indentationUnit.count,
                                             length: indentationUnit.count),
                             limit: mutation.limit)
            )
            return .discard
        }

        return .none
    }
}
