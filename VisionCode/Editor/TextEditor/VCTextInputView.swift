//
//  VCTextInputView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/28/24.
//

import Foundation
import UIKit

@objc protocol TextInputObserver {
    @objc func id() -> String
    
    @objc optional func textDidChange(in textView: VCTextInputView,
                                      oldRange: NSTextRange,
                                      newRange: NSTextRange,
                                      newValue: String)
    
    @objc optional func textWillChange(in textView: VCTextInputView)
}

class VCTextInputView: UIScrollView, NSTextViewportLayoutControllerDelegate, UITextInputTraits {
    let contentView = UIView()
    var layoutManager: NSTextLayoutManager
    var contentStore: NSTextContentStorage
    
    let carrot = Carrot()
    var carrotLocation: NSTextLocation? = nil
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
    
    var attributes: TextAttributes = [:]
    var highlightColor: UIColor = .blue
    
    var recycler = TextLayoutFragmentViewRecycler()
    
    var onDidSelectText: VoidLambda? = nil
    var onDidDeslectText: VoidLambda? = nil
    
    private var textObservers: [TextInputObserver] = []
    
    private var updateCursorLocationOnNextLayout: Bool = true
    
    var selectedTextRange: UITextRange? {
        get {
            // TODO: Get working
            //            guard let range = self.selectionRange else {
            //                return nil
            //            }
            //            return TextRange(range: range, provider: self.contentStore)
            
            return nil
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
    
    var lineHeight: CGFloat {
        var height: CGFloat = 0
        self.layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location,
                                                        options: [.ensuresLayout]) { fragment in
            height = fragment.layoutFragmentFrame.height
            return false
        }
        
        return height
    }
    
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
        layoutManager.enumerateTextLayoutFragments(from: textViewportLayoutController.viewportRange?.location) { fragment in
            return textViewportLayoutController.viewportRange?.contains(fragment.rangeInElement.endLocation) ?? true
        }
    }
    
    func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController, configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let (view, created) = recycler.retrieve(for: textLayoutFragment)
        if created {
            self.contentView.addSubview(view)
        }
        
        view.frame = textLayoutFragment.layoutFragmentFrame
    }
    
    func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        self.updateContentSizeIfNeeded()
        if self.updateCursorLocationOnNextLayout {
            self.updateCarrotLocation(scrollToCarrot: false)
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
    
    init(manager: NSTextLayoutManager, content: NSTextContentStorage) {
        self.layoutManager = manager
        self.contentStore = content
        self.fragmentLayerMap = .weakToWeakObjects()
        super.init(frame: .zero)
        
        self.addSubview(contentView)
        
        carrot.frame = CGRect(x: 0, y: 0, width: 6, height: 10)
        carrot.backgroundColor = .white
        carrot.isHidden = true
        self.contentView.addSubview(carrot)
        
        tapGesture.addTarget(self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)
        
        holdGesture.addTarget(self, action: #selector(onHoldGesture))
        holdGesture.minimumPressDuration = 0.25
        addGestureRecognizer(holdGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func closestLocation(to location: CGPoint) -> NSTextLocation? {
        guard let lineFragement = self.layoutManager.textLayoutFragment(for: location) else {
            return nil
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
        if closestXDelta > 10 && contentStore.offset(from: lineFragement.rangeInElement.location, to: lineFragement.rangeInElement.endLocation) > 1 {
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
        
        self.carrotLocation = closestLocation(to: adjustedLocation)
        self.updateCarrotLocation()
        
        self.verticalKeyPressStartX = self.carrot.frame.minX
    }
    
    @objc func onHoldGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let location = self.closestLocation(to: gesture.location(in: self.contentView)) else {
            return
        }
        
        if !self.isFirstResponder {
            _ = self.becomeFirstResponder()
        }
        
        switch(gesture.state) {
        case .began:
            self.selectionStart = location
            self.carrotLocation = location
            self.updateCarrotLocation()
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
            
            self.carrotLocation = location
            self.updateCarrotLocation()
            layoutManager.textViewportLayoutController.layoutViewport()
        case .cancelled:
            self.selectionStart = nil
            self.selectionRange = nil
            self.carrotLocation = location
            self.updateCarrotLocation()
            layoutManager.textViewportLayoutController.layoutViewport()
        case .possible:
            break
        case .ended:
            break
        case .failed:
            self.selectionStart = nil
            break
        @unknown default:
            break
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
        guard let carrotLocation = self.carrotLocation, let textStore = self.contentStore.textStorage else {
            return
        }
        
        self.inputDelegate?.textWillChange(self)
        
        for observer in textObservers {
            observer.textWillChange?(in: self)
        }
    
        let selectionRange = self.selectionRange
        self.selectionRange = nil
    
        // Update the text content
        textStore.beginEditing()
        if let selectionRange = selectionRange {
            let range = NSRange(selectionRange, provider: self.contentStore)
            textStore.replaceCharacters(in: range, with: text)
        } else {
            let offset = contentStore.offset(from: contentStore.documentRange.location, to: carrotLocation)
            textStore.insert(NSAttributedString(string: text, attributes: self.attributes), at: offset)
        }
        textStore.endEditing()
        
        for observer in textObservers {
            if let selectionRange = selectionRange {
                let end = contentStore.location(selectionRange.location, offsetBy: text.count)
                let newRange = NSTextRange(location: selectionRange.location, end: end)!
                observer.textDidChange?(in: self, oldRange: selectionRange, newRange: newRange, newValue: textStore.string)
            } else {
                let end = contentStore.location(carrotLocation, offsetBy: text.count)
                let newRange = NSTextRange(location: carrotLocation, end: end)!
                observer.textDidChange?(in: self, oldRange: NSTextRange(location: carrotLocation), newRange: newRange, newValue: textStore.string)
            }

        }
    
        layoutManager.textViewportLayoutController.layoutViewport()
        
        // Update teh carret
        if let selectionRange = selectionRange {
            self.carrotLocation = contentStore.location(selectionRange.location, offsetBy: text.count)
        } else {
            self.carrotLocation = contentStore.location(carrotLocation, offsetBy: text.count)
        }
        
        self.updateCarrotLocation()
        
        self.inputDelegate?.textDidChange(self)
    }
    
    func deleteBackward() {
        guard let textStore = contentStore.textStorage,
            let carrotLocation = self.carrotLocation else {
            return
        }
        
        self.inputDelegate?.textWillChange(self)
        for observer in textObservers {
            observer.textWillChange?(in: self)
        }
        
        var range: NSTextRange? = nil
        if let selectionRange = self.selectionRange {
            range = selectionRange
            self.selectionRange = nil
        } else if let start = contentStore.location(carrotLocation, offsetBy: -1) {
            range = NSTextRange(location: start, end: carrotLocation)
        }
        
        guard let range = range else {
            return
        }
        
        textStore.beginEditing()
        textStore.deleteCharacters(in: NSRange(range, provider: contentStore))
        textStore.endEditing()
        
        for observer in textObservers {
            observer.textDidChange?(in: self, oldRange: range, newRange: NSTextRange(location: range.location), newValue: textStore.string)
        }
        
        layoutManager.textViewportLayoutController.layoutViewport()
        
        self.carrotLocation = range.location
        updateCarrotLocation()
        
        self.inputDelegate?.textDidChange(self)
    }
    
    func updateCarrotLocation(scrollToCarrot: Bool = true) {
        guard let carrotLocation = self.carrotLocation,
              let lineFragment = self.layoutManager.textLayoutFragment(for: carrotLocation) else {
            return
        }
    
        var found = false
        self.layoutManager.enumerateCaretOffsetsInLineFragment(at: carrotLocation, using: { x, location, le, _ in
            if location.compare(carrotLocation) == .orderedSame {
                if le {
                    found = true
                    self.carrot.frame = CGRect(x: x, y: lineFragment.layoutFragmentFrame.minY, width: self.carrot.frame.width, height: lineFragment.layoutFragmentFrame.height)
                }
            }
        })
        
        if !found {
            self.carrot.frame = CGRect(x: lineFragment.layoutFragmentFrame.maxX, y: lineFragment.layoutFragmentFrame.minY, width: self.carrot.frame.width, height: lineFragment.layoutFragmentFrame.height)
        }
        
        if (self.carrot.frame.origin.y < self.contentOffset.y ||  self.carrot.frame.origin.y > self.contentOffset.y + self.frame.height) && scrollToCarrot {
            self.updateCursorLocationOnNextLayout = true
            self.scrollRectToVisible(self.carrot.frame, animated: true)
        }
    }
    
    func prepareForReplacement() {
        self.contentOffset = .zero
        _ = self.resignFirstResponder()
        for view in self.contentView.subviews {
            view.removeFromSuperview()
        }
        self.contentView.addSubview(carrot)
        recycler = TextLayoutFragmentViewRecycler()
    }
    
    override func becomeFirstResponder() -> Bool {
        carrot.isHidden = false
        carrot.startBlinking()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        self.carrot.stopBlinking()
        self.carrot.isHidden = true
        return super.resignFirstResponder()
    }
    
    @objc func upPressed() {
        self.clearSelectionRange()
        if self.verticalKeyPressStartX == nil {
            self.verticalKeyPressStartX = self.carrot.frame.minX
        }
        self.moveCursorVertically(lines: 1)
    }
    
    @objc func downPressed() {
        self.clearSelectionRange()
        if self.verticalKeyPressStartX == nil {
            self.verticalKeyPressStartX = self.carrot.frame.minX
        }
        self.moveCursorVertically(lines: -1)
    }
    
    @objc func rightPressed() {
        self.clearSelectionRange()
        self.moveCursorHorizontially(offset: 1)
        self.verticalKeyPressStartX = self.carrot.frame.minX
    }
    @objc func leftPressed() {
        self.clearSelectionRange()
        self.moveCursorHorizontially(offset: -1)
        self.verticalKeyPressStartX = self.carrot.frame.minX
    }
    
    func moveCursorHorizontially(offset: Int) {
        if let location = self.carrotLocation {
            self.carrotLocation = contentStore.location(location, offsetBy: offset)
            self.updateCarrotLocation()
        }
    }
    
    func moveCursorVertically(lines: Int) {
        guard isFirstResponder else {
            return
        }
        
        self.carrotLocation = closestLocation(to: 
                                                CGPoint(x: self.verticalKeyPressStartX!,
                                                        y: carrot.frame.minY - CGFloat(lines) * carrot.frame.height))
        self.updateCarrotLocation()
    }
    
    func clearSelectionRange() {
        self.selectionRange = nil
        self.layoutManager.textViewportLayoutController.layoutViewport()
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
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesBegan(presses, with: event)
            return
        }
    
        switch (press.key?.keyCode) {
        case .keyboardC:
            if press.key?.modifierFlags == .command {
                self.copySelection()
                return
            }
        case .keyboardX:
            if press.key?.modifierFlags == .command {
                self.cutSelection()
                return
            }
        default: break
        }
        
        super.pressesBegan(presses, with: event)
    }
}

public extension NSRange {
    init(_ textRange: NSTextRange, provider: NSTextElementProvider) {
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

        self.init(start..<end)
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

