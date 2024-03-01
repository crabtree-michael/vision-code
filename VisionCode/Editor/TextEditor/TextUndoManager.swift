//
//  TextUndoManager.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/28/24.
//

import Foundation
import UIKit


class TextUndoManager: UndoManager, TextInputObserver {
    func id() -> String {
        return self.uniqueID.uuidString
    }
    
    private let storage: NSTextContentStorage
    private let uniqueID: UUID
    
    init(storage: NSTextContentStorage) {
        self.uniqueID = UUID()
        self.storage = storage
        super.init()
    }
    
    func textViewWillInsert(_ textView: VCTextInputView, text: String, at location: NSTextLocation) {
        let endLocation = self.storage.location(location, offsetBy: text.count - 1)
        self.registerUndo(withTarget: self) { target in
            guard let endLocation = endLocation,
                  let range = NSTextRange(location: location, end: endLocation)else {
                // Something strange happened... we have to clear because now the other ranges won't work
                self.removeAllActions()
                return
            }
            
            textView.delete(range: range)
        }
    }
    
    func textViewWillPerform(_ textView: VCTextInputView, replacements: [Replacement]) {
        // We keep track of a text delta to offset the locations within the new document
        var undoRanges = [(String, NSRange)]()
        var textDelta = 0
        
        // Do replacements in reverse to start from the beginning of the document
        for replacement in replacements.reversed() {
            let range = replacement.range
            let text = replacement.text
            if let oldText = self.storage.string(in: range, inclusive: false) {
                let offset = self.storage.offset(from: self.storage.documentRange.location, to: range.location)
                let newRange = NSRange(location: offset + textDelta, length: text.count)
                undoRanges.append((oldText, newRange))
                textDelta += text.count - oldText.count
            } else {
                // Something strange happened... we need to remove all actions or we will be messed up
                self.removeAllActions()
                return
            }
        }
        
        // Put back ranges in order required by textfield
        undoRanges = undoRanges.reversed()
    
        self.registerUndo(withTarget: self) { _ in
            var replacements: [Replacement] = []
            for (oldText, range) in undoRanges {
                if let location = self.storage.location(self.storage.documentRange.location, offsetBy: range.lowerBound),
                    let end = self.storage.location(location, offsetBy: range.length),
                   let range = NSTextRange(location: location, end: end) {
                    replacements.append(Replacement(text: oldText, range: range))
                } else {
                    // Something strange happened... let's just stop and clear
                    self.removeAllActions()
                    break
                }
            }
            
            textView.perform(replacements: replacements)
        }
    }
    
    func textViewWillDelete(_ textView: VCTextInputView, charactersIn range: NSTextRange) {
        guard let text = self.storage.string(in: range, inclusive: true) else {
            // We have to clear here or all other values will be f***ed
            self.removeAllActions()
            return
        }
        
        self.registerUndo(withTarget: self) { _ in
            textView.insert(text: text, at: range.location)
        }
    }
    
    override func removeAllActions() {
        print("I had to remove all actions :(")
        super.removeAllActions()
    }
}

extension NSTextContentStorage {
    func string(in range: NSTextRange, inclusive: Bool) -> String? {
        guard let string = self.textStorage?.string else {
            return nil
        }
        let startOffset = self.offset(from: self.documentRange.location, to: range.location)
        let endOffset = self.offset(from: self.documentRange.location, to: range.endLocation)
        let startIndex = string.index(string.startIndex, offsetBy: startOffset)
        let endIndex = string.index(string.startIndex, offsetBy: endOffset)
        
        if inclusive {
            return String(string[startIndex...endIndex])
        } else {
            return String(string[startIndex..<endIndex])
        }
        
    }
}
