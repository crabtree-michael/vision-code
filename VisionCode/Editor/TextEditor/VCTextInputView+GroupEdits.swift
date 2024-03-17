//
//  VCTextInputView+GroupEdits.swift
//  VisionCode
//
//  Created by Michael Crabtree on 3/3/24.
//

import Foundation
import UIKit
import CodeEditLanguages

extension CodeLanguage {
    func commentStr() -> String? {
        switch(self) {
        case .agda, .haskell, .lua, .sql:
            return "--"
        case .bash, .dockerfile, .elixir, .julia, .perl, .python, .ruby, .toml, .yaml:
            return "#"
        case .c, .cSharp, .cpp, .javascript, .go, .goMod, .dart, .jsdoc, .jsx, .kotlin, .objc, .php, .rust, .scala, .swift, .tsx, .typescript, .verilog, .zig:
            return "//"
        case .css, .html, .json, .default, .markdown, .markdownInline, .ocaml, .ocamlInterface, .regex:
            return nil
        default:
            return nil
        }
    }
}


extension VCTextInputView {
    func tab(range: NSTextRange) {
        self.insert(string: self.tabWidth.tabString, atAllOccurancesOf: "\n", in: range)
    }
    
    func commentSelection() {
        var range: NSTextRange?
        if self.selectionRange != nil {
            range = self.selectionRange
        }
        else if let caretLocation = self.caretLocation,
                let start = self.contentStore.location(caretLocation, offsetBy: -1),
           let newRange = NSTextRange(location: start, end: caretLocation) {
            range = newRange
        }
        
        guard var range = range else {
            return
        }
        
        range = self.adjustRangeToIncludeNewLine(range, inclusive: true)
        self.comment(range: range)
    }
    
    func adjustRangeToIncludeNewLine(_ range: NSTextRange, inclusive: Bool) -> NSTextRange {
        guard let text = self.contentStore.string(in: range, inclusive: inclusive) else {
            return range
        }
        
        if text.hasPrefix("\n") {
            return range
        }
        
        let preceedingLocation = self.preceedingOccurance(of: "\n", at: range.location) ?? self.contentStore.documentRange.location
        guard let newRange = NSTextRange(location: preceedingLocation, end: range.endLocation) else {
            return range
        }
        
        return newRange
    }
    
    func comment(range: NSTextRange) {
        guard let commentStr = self.language.commentStr(),
                let text = self.contentStore.string(in: range, inclusive: false) else {
            return
        }
        
        if text.hasPrefix("\n\(commentStr)") {
            self.replaceOccurances(of: "\n\(commentStr)", with: "\n", in: range)
        } else {
            self.insert(string: commentStr, atAllOccurancesOf: "\n", in: range)
        }
    }
    
    func delete(occurancesOf replacementStr: String, in range: NSTextRange, allowSingleLines: Bool = false) {
        self.replaceOccurances(of: replacementStr, with: "", in: range)
    }
    
    func insert(string: String, atAllOccurancesOf replacementStr: String, in range: NSTextRange,
                allowSingleLines: Bool = false) {
        self.replaceOccurances(of: replacementStr, with: replacementStr + string, in: range)
    }
    
    func replaceOccurances(of matchStr: String, with replacementStr: String, in range: NSTextRange) {
        let documentStart = contentStore.documentRange.location
        guard let str = self.contentStore.string(in: range, inclusive: false),
              let globalOffset = range.offset(provider: self.contentStore) else {
            return
        }
        
        self.selectionRange = nil
        
        var replacements = [Replacement]()
        
        // Create replacements for every new line to add a tab to it
        str.iterateOverOccurances(of: matchStr) { range in
            if let start = self.contentStore.location(documentStart, offsetBy: range.lowerBound.utf16Offset(in: str) + globalOffset),
               let end = self.contentStore.location(documentStart, offsetBy: range.upperBound.utf16Offset(in: str) + globalOffset),
               let range = NSTextRange(location: start, end: end) {
                replacements.append(Replacement(text: replacementStr, range: range))
            }
            return true
        }
        
        // Add a no-op replacement for cursor placement
        replacements.append(Replacement(text: "", range: NSTextRange(location: range.endLocation, end: range.endLocation)!))
        
        // Perform replacements
        self.perform(replacements: replacements.reversed())
    }
    
    func line(at location: NSTextLocation) -> String? {
        let start = startOfLine(at: location)
        let end = endOfLine(at: location)
        if start.compare(end) == .orderedDescending {
            return ""
        }
        guard let range = NSTextRange(location: start, end: end) else {
            return nil
        }
        return self.contentStore.string(in: range, inclusive: true)
    }
    
    func endOfLine(at location: NSTextLocation) -> NSTextLocation {
        if let location = nextOccurance(of: "\n", at: location),
           let result = contentStore.location(location, offsetBy: -1) {
            return result
        }
        
        return self.contentStore.documentRange.endLocation
    }
    
    func startOfLine(at location: NSTextLocation) -> NSTextLocation {
        if let location = preceedingOccurance(of: "\n", at: location),
           let result = contentStore.location(location, offsetBy: 1) {
            return result
        }
        
        return self.contentStore.documentRange.location
    }
    
    func preceedingOccurance(of str: String, at location: NSTextLocation) -> NSTextLocation? {
        let documentStart = self.contentStore.documentRange.location
        var l: NSTextLocation? = self.contentStore.location(location, offsetBy: -1)
        while let location = l,
                location.compare(documentStart) == .orderedDescending {
            guard let range = NSTextRange(location: location, end: location) else {
                break
            }
            let character = self.contentStore.string(in: range, inclusive: true)
            if character == str {
                break
            }
            l = self.contentStore.location(location, offsetBy: -1)
        }
        
        return l
    }
    
    func nextOccurance(of str: String, at location: NSTextLocation) -> NSTextLocation? {
        let documentEnd = self.contentStore.documentRange.endLocation
        var l: NSTextLocation? = self.contentStore.location(location, offsetBy: 1)
        while let location = l,
              location.compare(documentEnd) == .orderedAscending {
            guard let range = NSTextRange(location: location, end: location) else {
                break
            }
            let character = self.contentStore.string(in: range, inclusive: true)
            if character == str {
                break
            }
            l = self.contentStore.location(location, offsetBy: 1)
        }
        
        return l
    }
}
