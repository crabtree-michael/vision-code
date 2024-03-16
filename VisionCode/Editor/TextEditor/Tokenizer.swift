//
//  Tokenizer.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/19/24.
//

import Foundation
import UIKit

class Tokenizer {
    private let provider: NSTextContentStorage
    private var acceptedCharacters = [String: Bool]()
    
    init(provider: NSTextContentStorage) {
        self.provider = provider
        
        let acceptableCharacters = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","_",
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        for c in acceptableCharacters {
            self.acceptedCharacters[c] = true
        }
    }
    
    func rangeForToken(at index: NSTextLocation) -> NSTextRange? {
        guard let content = self.provider.textStorage?.string else {
            return nil
        }
        
        let offset = self.provider.offset(from: self.provider.documentRange.location, to: index)
        var index = content.index(content.startIndex, offsetBy: offset)
        if index == content.endIndex {
            index = content.index(before: content.endIndex)
        }
        
        let startIndex = nextUnacceptableCharacter(in: content, at: index, direction: -1)
        let endIndex = nextUnacceptableCharacter(in: content, at: index, direction: 1)
        
        let startOffset = startIndex.utf16Offset(in: content)
        let endOffset = endIndex.utf16Offset(in: content)
        
        guard let startLocation = self.provider.location(self.provider.documentRange.location, offsetBy: startOffset),
              let endLocation = self.provider.location(self.provider.documentRange.location, offsetBy: endOffset) else {
            return nil
        }
        
        let range = NSTextRange(location: startLocation, end: endLocation)
        return range
    }
    
    private func nextUnacceptableCharacter(in string: String, at index: String.Index, direction: Int) -> String.Index {
        var i = index

        while(true) {
            let character = string[i].lowercased()
            if(!(self.acceptedCharacters[character] ?? false)
               || i == string.startIndex
               || i == string.endIndex) {
                return string.index(i, offsetBy: index == i ? 0 : -1 * direction)
            }
            i = string.index(i, offsetBy: direction)
        }
        
        return i
    }
}
