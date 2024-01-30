//
//  VCTextInputView+UITextInput.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/29/24.
//

import UIKit

extension VCTextInputView: UITextInput {
    var hasText: Bool {
        return contentStore.textStorage != nil
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var canResignFirstResponder: Bool {
        return true
    }
    
    
    func text(in range: UITextRange) -> String? {
         guard let range = range as? TextRange,
               let text = contentStore.textStorage?.string else {
             return nil
         }
        
         let start = text.index(text.startIndex, offsetBy: range.start.location)
         let end = text.index(text.startIndex, offsetBy: range.end.location)
         return String(text[start..<end])
     }
    
    func replace(_ range: UITextRange, withText text: String) {
        print("REplace rejected!")
    }
    
    
    var markedTextRange: UITextRange? {
         nil
    }
    
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        print("set as marked")
    }
    
    func unmarkText() {
        print("set as unamrked")
    }
    
    var beginningOfDocument: UITextPosition {
        return TextPosition(location: 0)
    }

    var endOfDocument: UITextPosition {
        return TextPosition(location: contentStore.textStorage?.length ?? 0)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        return TextRange(start: fromPosition as! TextPosition, end: toPosition as! TextPosition)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let p = position as? TextPosition else {
            return nil
        }
        
        return TextPosition(location: p.location + offset)
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        return TextPosition(location: (position as! TextPosition).location + offset)
    }
    
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard let a = position as? TextPosition,
              let b = position as? TextPosition else {
            return .orderedSame
        }
        
        if a.location == b.location {
            return .orderedSame
        } else if a.location < b.location {
            return .orderedAscending
        }
        return .orderedDescending
    }
    
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard let a = from as? TextPosition,
              let b = toPosition as? TextPosition else {
            return 0
        }
        
        return  b.location - a.location
    }
    
    var tokenizer: UITextInputTokenizer {
        get {
            return UITextInputStringTokenizer(textInput: self)
        }
    }
    
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        guard let range = range as? TextRange else {
            return nil
        }
        
        
        var farthest: NSTextLayoutFragment?
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.location(layoutManager.documentRange.location,
                                                                                offsetBy: range.start.location), options: [.ensuresLayout]) { fragment in
            guard let currentFragment = farthest else {
                farthest = fragment
                return true
            }
            
            switch(direction) {
            case .down:
                if fragment.layoutFragmentFrame.maxY > currentFragment.layoutFragmentFrame.maxY {
                    farthest = fragment
                }
            case .up:
                if fragment.layoutFragmentFrame.minY < currentFragment.layoutFragmentFrame.minY {
                    farthest = fragment
                }
            case .left:
                if fragment.layoutFragmentFrame.minX < currentFragment.layoutFragmentFrame.minX {
                    farthest = fragment
                }
            case .right:
                if fragment.layoutFragmentFrame.maxX > currentFragment.layoutFragmentFrame.maxX {
                    farthest = fragment
                }
            default: break
            }
            
            let offset = contentStore.offset(from: contentStore.documentRange.location, to: fragment.rangeInElement.endLocation)
            return offset < range.end.location
        }
        
        guard let farthest = farthest else {
            return nil
        }
        
        var location: NSTextLocation
        switch(direction) {
        case .down:
            location = farthest.rangeInElement.endLocation
        case .up:
            location = farthest.rangeInElement.location
        case .left:
            location = farthest.rangeInElement.location
        case .right:
            location = farthest.rangeInElement.location
        default:
            return nil
        }
        
        return TextPosition(location: location, provider: contentStore)
    }
    
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        
        return nil
    }
    
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        return .leftToRight
    }
    
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        print("SEt writing direct")
    }
    
    func firstRect(for range: UITextRange) -> CGRect {
        return CGRect(x: 0, y: 0, width: 10, height: 10)
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        return self.carrot.frame
    }
    
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        guard let location = self.closestLocation(to: point) else {
            return nil
        }
        
        return TextPosition(location: location, provider: self.contentStore)
    }
    
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        return nil
    }
    
    func characterRange(at point: CGPoint) -> UITextRange? {
        return nil
    }
}
