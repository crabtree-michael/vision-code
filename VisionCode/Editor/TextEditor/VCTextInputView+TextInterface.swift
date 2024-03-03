//
//  VCTextInputView+TextInterface.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/2/24.
//

import Foundation
import TextFormation
import TextStory

extension VCTextInputView: TextInterface {
    func substring(from range: NSRange) -> String? {
        guard let textRange = range.textRange(from: self.contentStore) else {
            return nil
        }
        return self.contentStore.string(in: textRange, inclusive: false)
    }
    
    func applyMutation(_ mutation: TextStory.TextMutation) {
        guard let range = mutation.range.textRange(from: self.contentStore) else {
            return
        }
        if range.isEmpty {
            self.insert(text: mutation.string, at: range.location, ignoreEditingDelegate: true)
        } else {
            self.replace(range: range, with: mutation.string)
        }
    }
}
