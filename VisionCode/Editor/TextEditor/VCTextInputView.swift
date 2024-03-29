//
//  VCTextInputView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/28/24.
//

import Foundation
import UIKit
import CodeEditLanguages

class Replacement: NSObject {
    var text: String
    var range: NSTextRange
    
    init(text: String, range: NSTextRange) {
        self.text = text
        self.range = range
    }
}

protocol TextViewEditDelegate {
    func textViewShouldInsert(_ textView: VCTextInputView, text: String, at location: NSTextLocation) -> Bool
    func textViewShouldDelete(_ textView: VCTextInputView, range: NSTextRange) -> Bool
}

@objc protocol TextInputObserver {
    @objc func id() -> String
    
    @objc optional func textDidFinishChanges(in textView: VCTextInputView, text: String)
    @objc optional func textDidChange(in textView: VCTextInputView,
                                      oldRange: NSTextRange,
                                      newRange: NSTextRange,
                                      newValue: String)
    
    @objc optional func textWillChange(in textView: VCTextInputView)
    
    @objc optional func textViewWillInsert(_ textView: VCTextInputView, text: String, at: NSTextLocation)
    @objc optional func textViewWillPerform(_ textView: VCTextInputView, replacements: [Replacement])
    @objc optional func textViewWillDelete(_ textView: VCTextInputView, charactersIn: NSTextRange)
}

class VCTextInputView: UIScrollView, NSTextViewportLayoutControllerDelegate, UITextInputTraits {
    let contentView = UIView()
    var layoutManager: NSTextLayoutManager
    var contentStore: NSTextContentStorage
    var theme: Theme
    var language: CodeLanguage = .default
    
    let caret = Caret()
    var caretLocation: NSTextLocation? = nil
    var selectionRange: NSTextRange? = nil {
        didSet {
            self.updateTextForSelectionRangeChanges(old: oldValue, new: self.selectionRange)
            if self.selectionRange != nil {
                self.onDidSelectText?()
            } else {
                self.onDidDeslectText?()
            }
        }
    }
    var selectionStart: NSTextLocation?
    
    var widestTextFragement: NSTextLayoutFragment?
    
    private var fragmentLayerMap: NSMapTable<NSTextLayoutFragment, UIView>
    
    let tapGesture = UITapGestureRecognizer()
    let holdGesture = UILongPressGestureRecognizer()
    let doubleTapGesture = UITapGestureRecognizer()
    var holdGestureIsInsideCarret: Bool = false
    
    var languageTokenizer: Tokenizer? = nil
    
    var attributes: TextAttributes = [:] {
        didSet {
            let oneLineStr = NSAttributedString(string: "One linj", attributes: attributes)
            let size = oneLineStr.size()
            
            self.lineHeight = size.height
        }
    }
    
    var highlightColor: UIColor {
        return theme.selectionColor
    }
    
    var recycler = TextLayoutFragmentViewRecycler()
    
    var onDidSelectText: VoidLambda? = nil
    var onDidDeslectText: VoidLambda? = nil
    var onOpenFindInFile: VoidLambda? = nil
    
    var tabWidth: TabWidth
    
    private var textObservers: [TextInputObserver] = []
    
    private var updateCursorLocationOnNextLayout: Bool = true
    
    var primaryUndoManager: UndoManager? = nil
    override var undoManager: UndoManager? {
        return primaryUndoManager
    }
    
    var selectedTextRange: UITextRange? {
        get {
            guard let range = self.selectionRange else {
                return nil
            }
            return TextRange(range: range, provider: self.contentStore)
        }
        set {
            print("Attempt to set selected text range ignored")
        }
        
    }
    var markedTextStyle: [NSAttributedString.Key : Any]?
    var inputDelegate: UITextInputDelegate?
    
    var verticalKeyPressStartX: CGFloat? = nil
    
    var autocorrectionType: UITextAutocorrectionType {
        get {
            return .no
        }
        set {}
    }
    
    var autocapitalizationType: UITextAutocapitalizationType {
        get {
            return .none
        }
        set {}
    }
    
    var insets: UIEdgeInsets? = nil {
        didSet {
            let left = CGFloat(insets?.left ?? 0)
            let top = CGFloat(insets?.top ?? 0)
            contentView.frame = CGRect(x: left, y: top, width: contentView.frame.width, height: contentView.frame.height)
        }
    }
    
    var lineHeight: CGFloat
    
    // TextInterface
    var selectedRange: NSRange {
        get {
            if let selectionRange = self.selectionRange {
                return NSRange(selectionRange, provider: self.contentStore)
            }
            if let cursorLocation = self.caretLocation {
                let offset = self.contentStore.offset(from: contentStore.documentRange.location, to: cursorLocation)
                return NSRange((offset..<offset))
            }
            
            return NSRange((0...0))
        }
        set {
            guard let range = newValue.textRange(from: self.contentStore) else {
                return
            }
            
            if range.isEmpty {
                self.caretLocation = range.location
                self.updateCaretLocation()
            } else {
                self.selectionRange = range
            }
        }
    }
    var length: Int {
        return self.contentStore.length
    }
    
    var editDelegate: TextViewEditDelegate?
    
    var shiftPressed: Bool = false
    
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            VCTextInputView.makeCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(self.upPressed)),
            VCTextInputView.makeCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(self.downPressed)),
            VCTextInputView.makeCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(self.leftPressed)),
            VCTextInputView.makeCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(self.rightPressed))
        ]
    }
    
    static func makeCommand(input: String, modifierFlags: UIKeyModifierFlags, action: Selector) -> UIKeyCommand {
        let command = UIKeyCommand(input: input, modifierFlags: modifierFlags, action: action)
        command.wantsPriorityOverSystemBehavior = true
        return command
    }
    
    func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        var rect = CGRect()
        let buffer = max(min(100, contentSize.height * 0.25), 500)
        rect.size = CGSize(width: frame.width, height: frame.height + buffer/2)
        rect.origin = CGPoint(x: contentOffset.x, y: contentOffset.y - buffer/2)
        return rect
    }
    
    func add(observer: TextInputObserver) {
        self.textObservers.append(observer)
    }
    
    func remove(observer: TextInputObserver) {
        self.textObservers.removeAll { o in
            o.id() == observer.id()
        }
    }
    
    func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        recycler.prepareForReuse()
    }
    
    func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let (view, created) = recycler.retrieve(for: textLayoutFragment)
        if created {
            view.hoverStyle = .init(effect: .lift)
            self.contentView.addSubview(view)
        }
        
        view.frame = textLayoutFragment.layoutFragmentFrame
        view.isHidden = false
    }
    
    func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        self.updateContentSizeIfNeeded()
        if self.updateCursorLocationOnNextLayout {
            self.updateCaretLocation(scrollToCaret: false)
        }
        for view in self.recycler.unusedViews() {
            view.isHidden = true
        }
    }
    
    func updateContentSizeIfNeeded() {
        let currentHeight = bounds.height
        let currentWidth = bounds.width
        var height: CGFloat = currentHeight
        let width: CGFloat = max(currentWidth, (self.widestTextFragement?.layoutFragmentFrame.width ?? 0) + (self.insets?.left ?? 0) + (self.insets?.right ?? 0))
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.endLocation,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY
            return false // stop
        }

        if abs(currentHeight - height) > 1e-10 || abs(currentWidth - width) > 1e-10 {
            let contentSize = CGSize(width: width, height: height)
            self.contentSize = contentSize
        }
    }
    
    func findWidestTextFragement() {
        var widest: NSTextLayoutFragment?
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: [.estimatesSize]) { fragment in
            guard let currentWidest = widest else {
                widest = fragment
                return true
            }
            
            if fragment.layoutFragmentFrame.size.width > currentWidest.layoutFragmentFrame.size.width {
                widest = fragment
            }
            
            return true
        }
        
        self.widestTextFragement = widest
    }
    
    init(manager: NSTextLayoutManager, content: NSTextContentStorage, theme: Theme) {
        self.layoutManager = manager
        self.contentStore = content
        self.fragmentLayerMap = .weakToWeakObjects()
        self.lineHeight = 12
        self.tabWidth = .fourTabs
        self.theme = theme
        super.init(frame: .zero)
        
        self.addSubview(contentView)
        
        caret.frame = CGRect(x: 0, y: 0, width: 6, height: 10)
        caret.backgroundColor = .white
        caret.isHidden = true
        caret.hoverStyle = .init(effect: .lift)
        self.contentView.addSubview(caret)
        
        tapGesture.addTarget(self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)
        
        doubleTapGesture.addTarget(self, action: #selector(onDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        
        holdGesture.addTarget(self, action: #selector(onHoldGesture))
        holdGesture.minimumPressDuration = 0.25
        addGestureRecognizer(holdGesture)
        
        self.addInteraction(UIPointerInteraction(delegate: self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func closestLocation(to location: CGPoint) -> NSTextLocation? {
        guard let lineFragement = self.layoutManager.textLayoutFragment(for: location) else {
            return contentStore.documentRange.endLocation
        }
        
        var closestX = lineFragement.layoutFragmentFrame.minX
        var closestXDelta = abs(location.x - closestX)
        var closestTextLocation = lineFragement.rangeInElement.location
        
        self.layoutManager.enumerateCaretOffsetsInLineFragment(at: lineFragement.rangeInElement.location) { x, textLocation, le, _ in
            if le {
                let delta = abs(location.x - x)
                if delta < closestXDelta {
                    closestX = x
                    closestXDelta = delta
                    closestTextLocation = textLocation
                }
            }
        }
        if closestXDelta > 3 && contentStore.offset(from: lineFragement.rangeInElement.location, to: lineFragement.rangeInElement.endLocation) > 1 {
            closestTextLocation = contentStore.location(closestTextLocation, offsetBy: 1)!
        }
        
        return closestTextLocation
    }
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        if !self.isFirstResponder {
            _ = self.becomeFirstResponder()
        }
        
        if selectionRange != nil {
            self.selectionRange = nil
            self.layoutManager.textViewportLayoutController.layoutViewport()
        }
        
        let location = gesture.location(in: self)
        let adjustedLocation = CGPoint(x: location.x - CGFloat(self.insets?.left ?? 0),
                                     y: location.y - CGFloat(self.insets?.top ?? 0))
        let newLocation = closestLocation(to: adjustedLocation)
        
        if let newLocation = newLocation,
            let currentLocation = self.caretLocation, shiftPressed {
            let order = currentLocation.compare(newLocation)
            let start = order == .orderedAscending ? currentLocation : newLocation
            let end = order == .orderedAscending ? newLocation : currentLocation
            self.selectionRange = NSTextRange(location: start, end: end)
            self.layoutManager.textViewportLayoutController.layoutViewport()
            return
        }
        
        self.caretLocation = newLocation
        self.updateCaretLocation()
        
        self.verticalKeyPressStartX = self.caret.frame.minX
    }
    
    @objc func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let location = self.closestLocation(to: gesture.location(in: self.contentView)),
              let range = self.languageTokenizer?.rangeForToken(at: location) else {
            return
        }
        
        if !self.isFirstResponder {
            _ = self.becomeFirstResponder()
        }
        
        // Tokenizer provides an inclusive range
        let endLocation = self.contentStore.location(range.endLocation, offsetBy: 1)
        let adjustedRange = NSTextRange(location: range.location, end: endLocation)
        
        self.selectionRange = adjustedRange
        self.caretLocation = adjustedRange?.endLocation
        self.updateCaretLocation()
        layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func caretHitFrame() -> CGRect {
        let padding: CGFloat = 10
        return CGRect(x: caret.frame.minX - padding, y: caret.frame.minY - padding, width: caret.frame.width + padding * 2, height: caret.frame.height + padding * 2)
    }
    
    @objc func onHoldGesture(_ gesture: UILongPressGestureRecognizer) {
        guard !self.holdGestureIsInsideCarret else {
            self.onCarretHoldGesture(gesture)
            return
        }
        
        let gestureLocation = gesture.location(in: self.contentView)
        guard let location = self.closestLocation(to: gestureLocation) else {
            return
        }
        
        if !self.isFirstResponder {
            _ = self.becomeFirstResponder()
        }
        
        switch(gesture.state) {
        case .began:
            guard !caret.frame.contains(gestureLocation) else {
                self.holdGestureIsInsideCarret = true
                self.onHoldGesture(gesture)
                return
            }
            
            self.selectionStart = location
            self.caretLocation = location
            self.updateCaretLocation()
            self.onDidSelectText?()
            layoutManager.textViewportLayoutController.layoutViewport()
        case .changed:
            if var start = selectionStart {
                var end = location
                let currentOffset = contentStore.offset(from: start, to: end)
                if currentOffset < 0 {
                    start = location
                    end = selectionStart!
                }
                
                let offset = contentStore.offset(from: start, to: end)
                let endLocation = contentStore.location(start, offsetBy: offset)
                self.selectionRange = NSTextRange(location: start, end: endLocation)
            }
            
            self.caretLocation = location
            self.updateCaretLocation()
            layoutManager.textViewportLayoutController.layoutViewport()
        case .cancelled:
            self.selectionStart = nil
            self.selectionRange = nil
            self.caretLocation = location
            self.updateCaretLocation()
            layoutManager.textViewportLayoutController.layoutViewport()
        case .possible:
            break
        case .ended:
            if self.selectionRange?.isEmpty ?? true {
                self.onDidDeslectText?()
            }
            break
        case .failed:
            self.selectionStart = nil
            break
        @unknown default:
            break
        }
    }
    
    @objc func onCarretHoldGesture(_ gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            self.caret.layer.shadowOffset = CGSize(width: 2, height: 2)
            self.caret.layer.shadowColor = UIColor.black.cgColor
            self.caret.layer.shadowOpacity = 1
        case .changed:
            let location = gesture.location(in: self.contentView)
            self.caret.center = location
            self.scrollToCaretIfNeeded()
        default:
            self.holdGestureIsInsideCarret = false
            self.caret.layer.shadowOpacity = 0
            let location = self.closestLocation(to: CGPoint(x: self.caret.frame.minX, y: self.caret.center.y))
            self.caretLocation = location
            self.updateCaretLocation()
            self.scrollToCaretIfNeeded()
        }
    }
    
    
    func updateTextForSelectionRangeChanges(old: NSTextRange?, new: NSTextRange?) {
        guard old != nil || new != nil else {
            // If nothing is set, this is the same as rendering a deselection of the whole document
            updateTextForSelectionRangeChanges(old: contentStore.documentRange, new: nil)
            return
        }
        guard let old = old else {
            updateTextForSelectionRangeChanges(old: new, new: new)
            return
        }
        guard let new = new else {
            // This is the end of rendering
            updateTextForSelectionRangeChanges(old: old,
                                               new: NSTextRange(location: contentStore.documentRange.location, end: contentStore.documentRange.location))
            return
        }
        
        self.inputDelegate?.selectionWillChange(self)

        layoutManager.removeRenderingAttribute(.backgroundColor, for: old)
        layoutManager.addRenderingAttribute(.backgroundColor, value: self.highlightColor, for: new)
        layoutManager.invalidateLayout(for: old)
        layoutManager.invalidateLayout(for: new)
        
        self.inputDelegate?.selectionDidChange(self)
    }
    
    func insertText(_ text: String) {
        var text = text
        if text == "“" || text == "”"{
            text = "\""
        }
        if text == "‘" || text == "’" {
            text = "'"
        }
        
        if let selectionRange = selectionRange {
            self.replace(range: selectionRange, with: text)
            self.selectionRange = nil
            return
        }
        
        if let location = caretLocation {
            self.insert(text: text, at: location)
            return
        }
    }
    
    func insert(text: String, at location: NSTextLocation, ignoreEditingDelegate: Bool = false, moveCaret: Bool = true) {
        guard let textStore = self.contentStore.textStorage else {
            return
        }
        
        if !ignoreEditingDelegate && 
            !(self.editDelegate?.textViewShouldInsert(self, text: text, at: location) ?? true) {
            return
        }
        
        self.inputDelegate?.textWillChange(self)
        
        for observer in textObservers {
            observer.textWillChange?(in: self)
            observer.textViewWillInsert?(self, text: text, at: location)
        }
        
        let offset = contentStore.offset(from: contentStore.documentRange.location, to: location)
        textStore.insert(NSAttributedString(string: text, attributes: self.attributes), at: offset)
        
        for observer in textObservers {
            let end = contentStore.location(location, offsetBy: text.count)
            let newRange = NSTextRange(location: location, end: end)!
            observer.textDidChange?(in: self, oldRange: NSTextRange(location: location), newRange: newRange, newValue: textStore.string)
            observer.textDidFinishChanges?(in: self, text: textStore.string)
        }
        
        layoutManager.textViewportLayoutController.layoutViewport()
        
        if moveCaret {
            self.caretLocation = contentStore.location(location, offsetBy: text.count)
            self.updateCaretLocation()
        }
        
        self.inputDelegate?.textDidChange(self)
    }
    
    func replace(range: NSTextRange, with text: String) {
        self.perform(replacements: [Replacement(text: text, range: range)])
    }
    
    // Replacements should be put in a descending order of range or else the ranges will change
    // As the replacements are being made
    func perform(replacements: [Replacement]) {
        guard let textStore = self.contentStore.textStorage else {
            return
        }
        
        self.inputDelegate?.textWillChange(self)
        
        for observer in textObservers {
            observer.textWillChange?(in: self)
            observer.textViewWillPerform?(self, replacements: replacements)
        }
        
        // We calculate the total text delta before the last location for the cursor placement at the end
        var textDelta: Int = 0
        for replacement in replacements.reversed().dropLast() {
            if let oldString = contentStore.string(in: replacement.range, inclusive: false) {
                textDelta += replacement.text.count - oldString.count
            }
        }
        
        for replacement in replacements {
            let text = replacement.text
            let range = replacement.range
            let r = NSRange(range, provider: self.contentStore)
            textStore.replaceCharacters(in: r, with: text)
            
            for observer in textObservers {
                let end = contentStore.location(range.location, offsetBy: text.count)
                let newRange = NSTextRange(location: range.location, end: end)!
                observer.textDidChange?(in: self, oldRange: range, newRange: newRange, newValue: textStore.string)
            }
        }
        
        for observer in textObservers {
            observer.textDidFinishChanges?(in: self, text: textStore.string)
        }
        
        self.selectionRange = nil

        layoutManager.textViewportLayoutController.layoutViewport()
        
        if let lastRange = replacements.first,
           let start = contentStore.location(lastRange.range.location, offsetBy: textDelta) {
            let text = lastRange.text
            self.caretLocation = contentStore.location(start, offsetBy: text.count)
            self.updateCaretLocation()
        }
        
        self.inputDelegate?.textDidChange(self)
    }
    
    func deleteBackward() {
        guard let caretLocation = self.caretLocation else {
            return
        }
        
        var range: NSTextRange? = nil
        if let selectionRange = self.selectionRange {
            let inclusiveEnd = contentStore.location(selectionRange.endLocation, offsetBy: -1)
            range = NSTextRange(location: selectionRange.location, end: inclusiveEnd)
            self.selectionRange = nil
        } else if let start = contentStore.location(caretLocation, offsetBy: -1) {
            range = NSTextRange(location: start, end: start)
        }
        
        guard let range = range else {
            return
        }
        
        self.delete(range: range)
    }
    
    func delete(range: NSTextRange, ignoreEditingDelegate: Bool = false) {
        guard let textStore = contentStore.textStorage else {
            return
        }
        
        if !ignoreEditingDelegate &&
            !(self.editDelegate?.textViewShouldDelete(self, range: range) ?? true) {
            return
        }
        
        let r = NSRange(range, provider: self.contentStore, inclusive: true)
        
        self.inputDelegate?.textWillChange(self)
        for observer in textObservers {
            observer.textWillChange?(in: self)
            observer.textViewWillDelete?(self, charactersIn: range)
        }
        
        textStore.beginEditing()
        textStore.deleteCharacters(in: r)
        textStore.endEditing()
        
        for observer in textObservers {
            if let exclusiveEnd = contentStore.location(range.endLocation, offsetBy: 1),
               let oldRange = NSTextRange(location: range.location, end: exclusiveEnd),
               let newRange = NSTextRange(location: range.location, end: range.location) {
                observer.textDidChange?(in: self,
                                        oldRange: oldRange,
                                        newRange: newRange,
                                        newValue: textStore.string)
            }
            
            observer.textDidFinishChanges?(in: self, text: textStore.string)
        }
        
        layoutManager.textViewportLayoutController.layoutViewport()
        
        self.caretLocation = range.location
        updateCaretLocation()
        
        self.inputDelegate?.textDidChange(self)
    }
    
    func setCaretToEndOfDocument() {
        let endLocation = contentStore.documentRange.endLocation
        var fragment: NSTextLayoutFragment?
        self.layoutManager.enumerateTextLayoutFragments(from: endLocation, options: [.reverse]) { f in
            fragment = f
            return false
        }
        
        guard let fragment = fragment else {
            return
        }
        
        let isDoubleFragment = abs(fragment.layoutFragmentFrame.height - lineHeight * 2) < 2
        
        self.caret.frame = CGRect(
            x: isDoubleFragment ? fragment.layoutFragmentFrame.minX : fragment.layoutFragmentFrame.maxX,
            y: fragment.layoutFragmentFrame.maxY - self.lineHeight,
            width: self.caret.frame.width,
            height: self.lineHeight)
    }
    
    func updateCaretLocation(scrollToCaret: Bool = true) {
        guard let caretLocation = self.caretLocation else {
            return
        }
        
        guard caretLocation.compare(contentStore.documentRange.endLocation) != .orderedSame else {
            self.setCaretToEndOfDocument()
            return
        }
        
        guard let lineFragment = self.layoutManager.textLayoutFragment(for: caretLocation) else {
            return
        }
    
        var found = false
        self.layoutManager.enumerateCaretOffsetsInLineFragment(at: caretLocation, using: { x, location, le, _ in
            if location.compare(caretLocation) == .orderedSame {
                if le {
                    found = true
                    self.caret.frame = CGRect(x: x, y: lineFragment.layoutFragmentFrame.minY, width: self.caret.frame.width, height: self.lineHeight)
                }
            }
        })
        
        if !found {
            self.caret.frame = CGRect(x: lineFragment.layoutFragmentFrame.maxX, y: lineFragment.layoutFragmentFrame.minY, width: self.caret.frame.width, height: self.lineHeight)
        }
        
        if scrollToCaret {
            self.scrollToCaretIfNeeded()
        }
    }
    
    func scrollToCaretIfNeeded() {
        if (self.caret.frame.origin.y < self.contentOffset.y ||  self.caret.frame.origin.y > self.contentOffset.y + self.frame.height) {
            self.updateCursorLocationOnNextLayout = true
            self.scrollRectToVisible(self.caret.frame, animated: true)
        }
    }
    
    func prepareForReplacement() {
        self.contentOffset = .zero
        _ = self.resignFirstResponder()
        for view in self.contentView.subviews {
            view.removeFromSuperview()
        }
        self.contentView.addSubview(caret)
        recycler = TextLayoutFragmentViewRecycler()
    }
    
    override func becomeFirstResponder() -> Bool {
        caret.isHidden = false
        caret.startBlinking()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        self.caret.stopBlinking()
        self.caret.isHidden = true
        return super.resignFirstResponder()
    }
    
    @objc func upPressed() {
        self.clearSelectionRange()
        if self.verticalKeyPressStartX == nil {
            self.verticalKeyPressStartX = self.caret.frame.maxX
        }
        self.moveCursorVertically(lines: 1)
    }
    
    @objc func downPressed() {
        self.clearSelectionRange()
        if self.verticalKeyPressStartX == nil {
            self.verticalKeyPressStartX = self.caret.frame.maxX
        }
        self.moveCursorVertically(lines: -1)
    }
    
    @objc func rightPressed() {
        self.clearSelectionRange()
        self.moveCursorHorizontially(offset: 1)
        self.verticalKeyPressStartX = self.caret.frame.minX
    }
    @objc func leftPressed() {
        self.clearSelectionRange()
        self.moveCursorHorizontially(offset: -1)
        self.verticalKeyPressStartX = self.caret.frame.minX
    }
    
    func moveCursorHorizontially(offset: Int) {
        guard let location = self.caretLocation else {
            return
        }
        
        if let newLocation =  contentStore.location(location, offsetBy: offset) {
            self.caretLocation = newLocation
        } else {
            if offset > 0 {
                self.caretLocation = contentStore.documentRange.endLocation
            } else {
                self.caretLocation = contentStore.documentRange.location
            }
        }
        
        self.updateCaretLocation()
    }
    
    func moveCursorVertically(lines: Int) {
        guard isFirstResponder else {
            return
        }
        
        guard let keyPress = self.verticalKeyPressStartX else {
            return
        }
        
        self.caretLocation = closestLocation(to:
                                                CGPoint(x: keyPress,
                                                        y: caret.frame.minY - CGFloat(lines) * caret.frame.height))
        self.updateCaretLocation()
    }
    
    func clearSelectionRange() {
        self.selectionRange = nil
        self.layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func insertTab() {
        if let selectionRange = self.selectionRange {
            let range = self.adjustRangeToIncludeNewLine(selectionRange, inclusive: false)
            let offet = self.tab(range: range)
            
            if let end = self.contentStore.location(range.endLocation, offsetBy: offet) {
                self.selectionRange = NSTextRange(location: range.location, end: end)
                self.layoutManager.textViewportLayoutController.layoutViewport()
            }
        } else {
            self.insertText(self.tabWidth.tabString)
        }
    }
    
    func unindent() {
        if let selectionRange = self.selectionRange {
            let range = self.adjustRangeToIncludeNewLine(selectionRange, inclusive: false)
            let offet = self.unindent(range: range)
            
            if let end = self.contentStore.location(range.endLocation, offsetBy: offet) {
                self.selectionRange = NSTextRange(location: range.location, end: end)
                self.layoutManager.textViewportLayoutController.layoutViewport()
            }
        } else if let caretLocation = self.caretLocation,
                  let start = self.contentStore.location(caretLocation, offsetBy: -1),
                  let newRange = NSTextRange(location: start, end: caretLocation) {
            let range = self.adjustRangeToIncludeNewLine(newRange, inclusive: false)
            let _ = self.unindent(range: range)
        }
    }
    

    @objc func copySelection() {
        guard let selection = selectionRange,
              let store = contentStore.textStorage else {
            return
        }
        
        let string = store.attributedSubstring(from: NSRange(selection, provider: self.contentStore))
        UIPasteboard.general.string = string.string
    }
    
    @objc func pasteText() {
        guard UIPasteboard.general.hasStrings, let string = UIPasteboard.general.string else {
            return
        }
        
        self.insertText(string)
    }
    
    override func paste(_ sender: Any?) {
        self.pasteText()
    }
    
    @objc func cutSelection() {
        self.copySelection()
        self.deleteBackward()
    }
    
    override func selectAll(_ sender: Any?) {
        self.selectionRange = self.contentStore.documentRange
        self.layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    override func copy(_ sender: Any?) {
        self.copySelection()
    }
    
    override func cut(_ sender: Any?) {
        self.cutSelection()
    }
    
    override func find(_ sender: Any?) {
        self.onOpenFindInFile?()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        shiftPressed = press.key?.modifierFlags == .shift
    
        switch (press.key?.keyCode) {
        case .keyboardF:
            if press.key?.modifierFlags == .command {
                self.find(self)
                return
            }
        case .keyboardTab:
            if press.key?.modifierFlags == .command || press.key?.modifierFlags == .shift {
                self.unindent()
            } else {
                self.insertTab()
            }
            return
        case .keyboardSlash:
            if press.key?.modifierFlags == .command {
                self.commentSelection()
            }
        default: break
        }
        
        super.pressesBegan(presses, with: event)
    }
    
    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let press = presses.first {
            shiftPressed = press.key?.modifierFlags == .shift
        }
        super.pressesChanged(presses, with: event)
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        shiftPressed = false
        super.pressesCancelled(presses, with: event)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        shiftPressed = false
        super.pressesEnded(presses, with: event)
    }
}

public extension NSRange {
    init(_ textRange: NSTextRange, provider: NSTextElementProvider, inclusive: Bool = false) {
        let docLocation = provider.documentRange.location

        let start = provider.offset?(from: docLocation, to: textRange.location) ?? NSNotFound
        if start == NSNotFound {
            self.init(location: start, length: 0)
            return
        }

        let end = provider.offset?(from: docLocation, to: textRange.endLocation) ?? NSNotFound
        if end == NSNotFound {
            self.init(location: NSNotFound, length: 0)
            return
        }
        
        if !inclusive {
            self.init(start..<end)
        } else {
            self.init(start...end)
        }
    }
}

public extension NSTextRange {
    func offset(provider: NSTextElementProvider) -> Int? {
        return provider.offset?(from: provider.documentRange.location, to: self.location)
    }
    
    func endOffset(provider: NSTextElementProvider) -> Int? {
        return provider.offset?(from: provider.documentRange.location, to: self.endLocation)
    }
}

public extension String {
    func iterateOverOccurances(of str: String, block: @escaping (Range<Substring.Index>) -> Bool) {
        var currentIndex = self.startIndex
        while (currentIndex < self.endIndex) {
            let substring = self[currentIndex...]
            if let range = substring.firstRange(of: str) {
                let shouldContinue = block(range)
                guard shouldContinue else {
                    return
                }
                currentIndex = range.upperBound
            } else {
                currentIndex = self.endIndex
            }
        }
    }
}
