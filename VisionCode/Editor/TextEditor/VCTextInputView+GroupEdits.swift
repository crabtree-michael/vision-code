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
    
    func comment(range: NSTextRange) {
        guard let commentStr = self.language.commentStr() else {
            return
        }
        let line = self.line(at: range.location)
        if line?.hasPrefix(commentStr) ?? false {
            self.replaceOccurances(of: "\n\(commentStr)", with: "\n", in: range, allowSingleLines: true)
        } else {
            self.insert(string: commentStr, atAllOccurancesOf: "\n", in: range, allowSingleLines: true)
        }
    }
    
    func commentSelection() {
        if let range = self.selectionRange {
            self.comment(range: range)
            return
        }
        if let carrotLocation = self.carrotLocation,
           let range = NSTextRange(location: carrotLocation, end: carrotLocation){
            self.comment(range: range)
            return
        }
    }
    
    func delete(occurancesOf replacementStr: String, in range: NSTextRange, allowSingleLines: Bool = false) {
        self.replaceOccurances(of: replacementStr, with: "", in: range)
    }
    
    func insert(string: String, atAllOccurancesOf replacementStr: String, in range: NSTextRange,
                allowSingleLines: Bool = false) {
        self.replaceOccurances(of: replacementStr, with: replacementStr + string, in: range)
    }
    
    func replaceOccurances(of matchStr: String, with replacementStr: String, in range: NSTextRange, allowSingleLines: Bool = false) {
        let documentStart = contentStore.documentRange.location
        guard let str = self.contentStore.string(in: range, inclusive: false),
              let globalOffset = range.offset(provider: self.contentStore) else {
            return
        }
        
        self.selectionRange = nil
        
        var replacements = [Replacement]()
        
        // This section handles lines that are not completely selected
        // We find the first occurance of the replacmentStr and at that to be tabbed
        let location = self.contentStore.location(self.startOfLine(at: range.location), offsetBy: -1)!
        let lineRange = NSTextRange(location: location,
                                end: self.contentStore.location(location, offsetBy: 1)!)!
        if location.compare(range.location) == .orderedSame {
            // Do nothing the whole line was selected
        } else if location.compare(documentStart) == .orderedSame {
            replacements.append(Replacement(text: replacementStr,
                                            range: lineRange))
        } else {
            replacements.append(Replacement(text: replacementStr,
                                            range: lineRange))
        }
        
        // Create replacements for every new line to add a tab to it
        str.iterateOverOccurances(of: matchStr) { range in
            if let start = self.contentStore.location(documentStart, offsetBy: range.lowerBound.utf16Offset(in: str) + globalOffset),
               let end = self.contentStore.location(documentStart, offsetBy: range.upperBound.utf16Offset(in: str) + globalOffset),
               let range = NSTextRange(location: start, end: end) {
                replacements.append(Replacement(text: replacementStr, range: range))
            }
            return true
        }
        
        // Find the only replacement we have is the one we forced then just replace the range with a tab
        guard (replacements.count > 1 || allowSingleLines) else {
            self.replace(range: range, with: matchStr)
            return
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
        var l: NSTextLocation? = location
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
