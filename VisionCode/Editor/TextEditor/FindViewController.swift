//
//  FindViewController.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/14/24.
//

import Foundation
import UIKit

class Search {
    var storage: NSTextContentStorage
    var query: String
    var results = [NSTextRange]()
    var cancelled = false
    var selectedIndex: Int? = nil
    
    init(with query: String, storage: NSTextContentStorage) {
        self.query = query
        self.storage = storage
    }
    
    func perform() {
        guard let content = storage.textStorage?.string else {
            return
        }
        
        var currentIndex = content.startIndex
        while (currentIndex < content.endIndex && !cancelled) {
            let substring = content[currentIndex...]
            if let range = substring.firstRange(of: self.query) {
                if let start = storage.location(storage.documentRange.location, offsetBy: range.lowerBound.utf16Offset(in: content)),
                   let end = storage.location(storage.documentRange.location, offsetBy: range.upperBound.utf16Offset(in: content)),
                   let range = NSTextRange(location: start, end: end ) {
                    self.results.append(range)
                }
                currentIndex = content.index(after: range.upperBound)
            } else {
                currentIndex = content.endIndex
            }
        }
    }
    
    func moveToNextIndexIfPossible() -> Bool {
        guard (selectedIndex ?? 0) < self.results.count else {
            return false
        }
        
        guard let currentIndex = selectedIndex else {
            selectedIndex = 0
            return true
        }
        
        guard currentIndex + 1 < self.results.count else {
            return false
        }
        
        selectedIndex = currentIndex + 1
        return true
    }
    
    func moveBackIfPossible() -> Bool {
        guard self.results.count > 0 else {
            return false
        }
        
        guard let currentIndex = selectedIndex else {
            selectedIndex = self.results.count - 1
            return true
        }
        
        guard currentIndex > 0 else {
            return false
        }
        
        selectedIndex = currentIndex - 1
        return true
    }
    
    func currentSelection() -> NSTextRange? {
        guard let selectedIndex = selectedIndex else {
            return nil
        }
        
        return self.results[selectedIndex]
    }
}

protocol FindViewportController {
    func scroll(to point: CGPoint)
}

class UpDownControlSegment: UIView {
    var isEnabled: Bool = true {
        didSet {
            self.down.isEnabled = isEnabled
            self.up.isEnabled = isEnabled
        }
    }
    let down: UIButton
    let up: UIButton
    
    override init(frame: CGRect) {
        down = UIButton(type: .custom)
        down.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        down.frame = CGRect(x: 0, y: 0, width: 25, height: frame.height)
        down.tintColor = .white
        
        up = UIButton(type: .custom)
        up.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        up.frame = CGRect(x: frame.width - 25, y: 0, width: 25, height: frame.height)
        up.tintColor = .white
        
        super.init(frame: frame)
        
        self.addSubview(up)
        self.addSubview(down)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FindViewController: UIViewController, UITextFieldDelegate {
    var width: CGFloat = 335
    var height: CGFloat = 50
    
    var didSetIsActive: ((Bool) -> ())? = nil
    var isActive: Bool {
        didSet {
            self.view.isHidden = !isActive
            if isActive && oldValue != isActive {
                self.textField.becomeFirstResponder()
            }
            if isActive != oldValue && !isActive {
                self.removeAllAttributes()
                self.layoutManager.textViewportLayoutController.layoutViewport()
            }
            self.didSetIsActive?(isActive)
        }
    }
    
    let containerView = UIView()
    let textField = UITextField()
    
    var layoutManager: NSTextLayoutManager
    var storage: NSTextContentStorage
    
    var currentSearch: Search? {
        didSet {
            if currentSearch == nil {
                self.controls.isEnabled = false
                self.resultCountLabel.text = ""
            }
        }
    }
    
    var viewportController: FindViewportController? = nil
    
    private var allActiveAttributes = [RangedAttribute]()
    
    let resultBackgroundColor = UIColor.red.withAlphaComponent(0.4)
    let highlightedResultBackgroundColor = UIColor.red
    
    let controls: UpDownControlSegment
    let close: UIButton
    
    let resultCountLabel: UILabel
    
    init(layoutManager: NSTextLayoutManager, storage: NSTextContentStorage) {
        self.layoutManager = layoutManager
        self.storage = storage
        isActive = true
        self.controls = UpDownControlSegment(frame: CGRect(x: 0, y: 0, width: 55, height: 50))
        self.resultCountLabel = UILabel()
        self.resultCountLabel.text = ""
        self.close = UIButton(type: .close)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.view.layer.shadowColor = UIColor.black.cgColor
        self.view.layer.shadowOpacity = 0.5
        self.view.layer.shadowRadius = 3
        self.view.layer.shadowOffset = CGSize(width: 2, height: 2)
        
        self.view.addSubview(containerView)
        containerView.backgroundColor = .gray
        containerView.addSubview(textField)
        containerView.layer.cornerRadius = 10
        
        self.containerView.addSubview(close)
        close.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            close.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            close.widthAnchor.constraint(equalToConstant: 25),
            close.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            close.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
        close.addTarget(self, action: #selector(self.closeWindow), for: .touchUpInside)
        
        self.containerView.addSubview(controls)
        controls.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controls.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -5),
            controls.widthAnchor.constraint(equalToConstant: 50),
            controls.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            controls.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        controls.isEnabled = false
        controls.up.addTarget(self, action: #selector(self.moveResultBackward), for: .touchUpInside)
        controls.down.addTarget(self, action: #selector(self.moveResultForward), for: .touchUpInside)
        
        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = .white
        
        textField.leftView = iconView
        textField.placeholder = "Find"
        textField.frame = containerView.frame
        textField.addSubview(iconView)
        textField.leftViewMode = .always
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.leftAnchor.constraint(equalTo: close.rightAnchor, constant: 5).isActive = true
        textField.rightAnchor.constraint(equalTo: controls.leftAnchor).isActive = true
        textField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.autocapitalizationType = .none
        textField.delegate = self
        
        textField.addSubview(resultCountLabel)
        textField.rightView = resultCountLabel
        textField.rightViewMode = .always
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        performSearch()
    }
    
    @objc func moveResultForward() {
        _ = self.advanceSearhIndex(forward: true)
    }
    
    @objc func moveResultBackward() {
        _ = self.advanceSearhIndex(forward: false)
    }
    
    @objc func closeWindow() {
        self.isActive = false
    }
    
    func performSearch() {
        guard let query = textField.text else {
            return
        }
        guard query.count > 0 else {
            self.currentSearch = nil
            self.resultCountLabel.text = ""
            self.controls.isEnabled = false
            self.removeAllAttributes()
            self.layoutManager.textViewportLayoutController.layoutViewport()
            return
        }
        
        let search = Search(with: query, storage: storage)
        search.perform()
        currentSearch = search
        
        self.controls.isEnabled = !search.results.isEmpty
        self.resultCountLabel.text = "\(search.results.count) results"
        
        self.removeAllAttributes()
        for range in search.results {
            self.addAttribute(.backgroundColor, value: resultBackgroundColor, for: range)
        }
        
        layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.currentSearch == nil {
            self.performSearch()
        }
        return !advanceSearhIndex(forward: true)
    }
    
    func advanceSearhIndex(forward: Bool) -> Bool {
        guard let search = self.currentSearch else {
            return true
        }
        
        self.removeAttributeForCurrentSelection()
        self.addNormalAttributeForCurrentSelection()
        
        let didAdvance: Bool
        if forward {
            didAdvance = search.moveToNextIndexIfPossible()
        } else {
            didAdvance = search.moveBackIfPossible()
        }
        
        self.resultCountLabel.text = "\((search.selectedIndex ?? 0) + 1) of \(search.results.count)"
       
        self.addHighlightAttributeForCurrentSelection()
        
        if let rect = rectForCurrentSelection() {
            self.viewportController?.scroll(to: rect.origin)
        }
        self.layoutManager.textViewportLayoutController.layoutViewport()
        
        return !didAdvance
    }
    
    func removeAttributeForCurrentSelection() {
        guard let range = self.currentSearch?.currentSelection() else {
            return
        }
        
        self.removeAttribute(for: range)
    }
    
    func addHighlightAttributeForCurrentSelection() {
        guard let range = self.currentSearch?.currentSelection() else {
            return
        }
        
        self.addAttribute(.backgroundColor, value: highlightedResultBackgroundColor, for: range)
    }
    
    func addNormalAttributeForCurrentSelection() {
        guard let range = self.currentSearch?.currentSelection() else {
            return
        }
        
        self.addAttribute(.backgroundColor, value: resultBackgroundColor, for: range)
    }
    
    
    func rectForCurrentSelection() -> CGRect? {
        guard let selection = self.currentSearch?.currentSelection() else {
            return nil
        }
        
        var rect: CGRect? = nil
        layoutManager.enumerateTextLayoutFragments(from: selection.location) { fragment in
            guard fragment.rangeInElement.intersects(selection) else {
                return false
            }
            
            rect = fragment.layoutFragmentFrame
            return true
        }
        
        return rect
    }
    
    func textDidChange() {
        if self.allActiveAttributes.count > 0 {
            self.removeAllAttributes()
            layoutManager.textViewportLayoutController.layoutViewport()
            self.currentSearch = nil
        }
    }
    
    private func addAttribute(_ attribute: NSAttributedString.Key, value: Any, for range: NSTextRange)
    {
        self.allActiveAttributes.append(RangedAttribute(attribute: attribute, range: range))
        layoutManager.addRenderingAttribute(attribute, value: value, for: range)
    }
    
    private func removeAllAttributes() {
        for range in self.allActiveAttributes {
            layoutManager.removeRenderingAttribute(range.attribute, for: range.range)
        }

        allActiveAttributes = []
    }
    
    private func removeAttribute(for range: NSTextRange) {
        for (offset, attr) in self.allActiveAttributes.enumerated() {
            if attr.range == range {
                layoutManager.removeRenderingAttribute(attr.attribute, for: range)
                self.allActiveAttributes.remove(at: offset)
                return
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        containerView.frame = CGRect(x: self.view.frame.width - width - 2, y: 0, width: width - 2, height: height)
    }
}
