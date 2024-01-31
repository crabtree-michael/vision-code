//
//  VCTextInputView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/28/24.
//

import Foundation
import UIKit

class VCTextInputView: UIScrollView, NSTextViewportLayoutControllerDelegate, UITextInputTraits {
    let contentView = UIView()
    var layoutManager: NSTextLayoutManager
    var contentStore: NSTextContentStorage
    
    let carrot = Carrot()
    var carrotLocation: NSTextLocation? = nil
    
    var widestTextFragement: NSTextLayoutFragment?
    
    private var fragmentLayerMap: NSMapTable<NSTextLayoutFragment, UIView>
    
    let tapGesture = UITapGestureRecognizer()
    
    var attributes: TextAttributes = [:]
    
    var recycler = TextLayoutFragmentViewRecycler()
    
    var selectedTextRange: UITextRange?
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
        self.selectedTextRange = nil
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
        
        print(lineFragement.rangeInElement)
        self.layoutManager.enumerateCaretOffsetsInLineFragment(at: lineFragement.rangeInElement.location) { x, textLocation, le, _ in
            print(x, le, textLocation)
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
        
        let location = gesture.location(in: self)
        let adjustedLocation = CGPoint(x: location.x - CGFloat(self.insets?.left ?? 0),
                                     y: location.y - CGFloat(self.insets?.top ?? 0))
        
        self.carrotLocation = closestLocation(to: adjustedLocation)
        self.updateCarrotLocation()
        
        self.verticalKeyPressStartX = self.carrot.frame.minX
    }
    
    func insertText(_ text: String) {
        guard let carrotLocation = self.carrotLocation, let textStore = self.contentStore.textStorage else {
            return
        }
        
        let offset = contentStore.offset(from: contentStore.documentRange.location, to: carrotLocation)
    
        textStore.beginEditing()
        textStore.insert(NSAttributedString(string: text, attributes: self.attributes), at: offset)
        textStore.endEditing()
        
        layoutManager.textViewportLayoutController.layoutViewport()
        
        self.carrotLocation = contentStore.location(carrotLocation, offsetBy: 1)
        self.updateCarrotLocation()
    }
    
    func deleteBackward() {
        guard let textStore = contentStore.textStorage,
            let carrotLocation = self.carrotLocation else {
            return
        }

        if let start = contentStore.location(carrotLocation, offsetBy: -1),
            let range = NSTextRange(location: start, end: carrotLocation) {
            
            textStore.beginEditing()
            textStore.deleteCharacters(in: NSRange(range, provider: contentStore))
            textStore.endEditing()
            
            layoutManager.textViewportLayoutController.layoutViewport()
            
            self.carrotLocation = contentStore.location(carrotLocation, offsetBy: -1)
            updateCarrotLocation()
        }
    }
    
    func updateCarrotLocation() {
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
        if self.verticalKeyPressStartX == nil {
            self.verticalKeyPressStartX = self.carrot.frame.minX
        }
        self.moveCursorVertically(lines: 1)
    }
    
    @objc func downPressed() {
        if self.verticalKeyPressStartX == nil {
            self.verticalKeyPressStartX = self.carrot.frame.minX
        }
        self.moveCursorVertically(lines: -1)
    }
    
    @objc func rightPressed() {
        self.moveCursorHorizontially(offset: 1)
        self.verticalKeyPressStartX = self.carrot.frame.minX
    }
    @objc func leftPressed() {
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

