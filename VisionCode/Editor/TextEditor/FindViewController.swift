//
//  FindViewController.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/14/24.
//

import Foundation
import UIKit
import SwiftUI

enum FindInFileState {
    case hidden
    case find
    case findAndReplace
}

class Search {
    var storage: NSTextContentStorage
    var query: String
    var results = [NSTextRange]()
    var cancelled = false
    var selectedIndex: Int? = nil
    
    init(with query: String, storage: NSTextContentStorage) {
        self.query = query.uppercased()
        self.storage = storage
    }
    
    func perform() {
        guard let content = storage.textStorage?.string.uppercased() else {
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
            selectedIndex = 0
            return true
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
    func replace(_ range: NSTextRange, with value: String)
    func replaceAll(_ range: [NSTextRange], with value: String)
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
    let defaultHeight: CGFloat = 50
    var width: CGFloat = 335
    var height: CGFloat = 50
    
    var didSetState: ((FindInFileState) -> ())? = nil
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
            if isActive {
                self.didSetState?(self.isShowingReplace ? .findAndReplace : .find)
            } else {
                self.didSetState?(.hidden)
            }
        }
    }
    
    let containerView = UIView()
    let textField = UITextField()
    let resultCountLabel: UILabel
    
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
    
    let replaceTextField = UITextField()
    let replaceContainerView = UIView()
    let openReplaceButton: UIButton
    let replaceButton: UIButton
    let replaceAllButton: UIButton
    var isShowingReplace = false
    
    init(layoutManager: NSTextLayoutManager, storage: NSTextContentStorage) {
        self.layoutManager = layoutManager
        self.storage = storage
        isActive = true
        self.controls = UpDownControlSegment(frame: CGRect(x: 0, y: 0, width: 55, height: 50))
        self.resultCountLabel = UILabel()
        self.resultCountLabel.text = ""
        self.close = UIButton(type: .close)
        self.openReplaceButton = UIButton(type: .custom)
        self.replaceAllButton = UIButton(type: .custom)
        self.replaceButton = UIButton(type: .custom)
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
            close.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            close.heightAnchor.constraint(equalToConstant: defaultHeight)
        ])
        close.addTarget(self, action: #selector(self.closeWindow), for: .touchUpInside)
        
        self.containerView.addSubview(openReplaceButton)
        openReplaceButton.setImage(UIImage(systemName: "chevron.forward")?.withTintColor(.white), for: .normal)
        openReplaceButton.tintColor = .white
        openReplaceButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            openReplaceButton.leftAnchor.constraint(equalTo: close.rightAnchor),
            openReplaceButton.widthAnchor.constraint(equalToConstant: 25),
            openReplaceButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            openReplaceButton.heightAnchor.constraint(equalToConstant: defaultHeight)
        ])
        openReplaceButton.addTarget(self, action: #selector(self.toggleReplace), for: .touchUpInside)
        
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
        textField.leftAnchor.constraint(equalTo: openReplaceButton.rightAnchor, constant: 5).isActive = true
        textField.widthAnchor.constraint(equalToConstant: 200).isActive = true
        textField.heightAnchor.constraint(equalToConstant: defaultHeight).isActive = true
        textField.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.autocapitalizationType = .none
        textField.delegate = self
        
        textField.addSubview(resultCountLabel)
        textField.rightView = resultCountLabel
        textField.rightViewMode = .always
        textField.autocorrectionType = .no
        
        containerView.addSubview(replaceContainerView)
        replaceContainerView.isHidden = true
        replaceContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            replaceContainerView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            replaceContainerView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            replaceContainerView.topAnchor.constraint(equalTo: textField.bottomAnchor),
            replaceContainerView.heightAnchor.constraint(equalToConstant: defaultHeight)
        ])
        
        replaceContainerView.addSubview(replaceTextField)
        replaceContainerView.addSubview(replaceAllButton)
        replaceContainerView.addSubview(replaceButton)
        
        let replaceIconView = UIImageView(image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis"))
        replaceIconView.tintColor = .white
        
        replaceTextField.translatesAutoresizingMaskIntoConstraints = false
        replaceTextField.placeholder = "Replace"
        replaceTextField.leftView = replaceIconView
        replaceTextField.leftViewMode = .always
        replaceTextField.delegate = self
        replaceTextField.autocapitalizationType = .none
        replaceTextField.autocorrectionType = .no
        NSLayoutConstraint.activate([
            replaceTextField.leftAnchor.constraint(equalTo: replaceContainerView.leftAnchor, constant: 5),
            replaceTextField.rightAnchor.constraint(equalTo: replaceButton.leftAnchor),
            replaceTextField.bottomAnchor.constraint(equalTo: replaceContainerView.bottomAnchor),
            replaceTextField.heightAnchor.constraint(equalTo: replaceContainerView.heightAnchor)
        ])
        
        replaceAllButton.setImage(UIImage(systemName: "arrowshape.turn.up.left.2.fill"), for: .normal)
        replaceAllButton.tintColor = .white
        replaceAllButton.isEnabled = false
        replaceAllButton.translatesAutoresizingMaskIntoConstraints = false
        replaceAllButton.addTarget(self, action: #selector(performReplaceAll), for: .touchUpInside)
        NSLayoutConstraint.activate([
            replaceAllButton.centerXAnchor.constraint(equalTo: controls.up.centerXAnchor),
            replaceAllButton.widthAnchor.constraint(equalToConstant: 25),
            replaceAllButton.bottomAnchor.constraint(equalTo: replaceContainerView.bottomAnchor),
            replaceAllButton.heightAnchor.constraint(equalTo: replaceContainerView.heightAnchor)
        ])
        
        replaceButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.fill"), for: .normal)
        replaceButton.tintColor = .white
        replaceButton.isEnabled = false
        replaceButton.addTarget(self, action: #selector(performReplace), for: .touchUpInside)
        replaceButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            replaceButton.centerXAnchor.constraint(equalTo: controls.down.centerXAnchor),
            replaceButton.widthAnchor.constraint(equalToConstant: 25),
            replaceButton.bottomAnchor.constraint(equalTo: replaceContainerView.bottomAnchor),
            replaceButton.heightAnchor.constraint(equalTo: replaceContainerView.heightAnchor)
        ])
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
    
    @objc func toggleReplace() {
        self.isShowingReplace = !self.isShowingReplace
        self.replaceContainerView.isHidden = !self.isShowingReplace
        
        let containerViewHeight: CGFloat = isShowingReplace ? defaultHeight * 2 : defaultHeight
        height = containerViewHeight
        self.containerView.frame = CGRect(x: containerView.frame.minX,
                                          y: containerView.frame.minY,
                                          width: containerView.frame.width,
                                          height: containerViewHeight)
        
        let openImage = isShowingReplace ? "chevron.down" : "chevron.forward"
        self.openReplaceButton.setImage(UIImage(systemName: openImage), for: .normal)
        
        self.didSetState?(self.isShowingReplace ? .findAndReplace : .find)
    }
    
    func performSearch() {
        guard let query = textField.text else {
            return
        }
        guard query.count > 0 else {
            self.currentSearch = nil
            self.resultCountLabel.text = ""
            self.controls.isEnabled = false
            self.replaceButton.isEnabled = false
            self.replaceAllButton.isEnabled = false
            self.removeAllAttributes()
            self.layoutManager.textViewportLayoutController.layoutViewport()
            return
        }
        
        self.replaceButton.isEnabled = false
        self.replaceAllButton.isEnabled = false
        
        let search = Search(with: query, storage: storage)
        search.perform()
        currentSearch = search
        
        self.controls.isEnabled = !search.results.isEmpty
        self.replaceAllButton.isEnabled = !search.results.isEmpty
        self.resultCountLabel.text = "\(search.results.count) results"
        
        self.removeAllAttributes()
        for range in search.results {
            self.addAttribute(.backgroundColor, value: resultBackgroundColor, for: range)
        }
        
        layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.replaceTextField {
            self.performReplace()
            return true
        }
        
        if self.currentSearch == nil {
            self.performSearch()
        }
        return !advanceSearhIndex(forward: true)
    }
    
    @objc func performReplace() {
        if let currentSearch = self.currentSearch,
            let range = currentSearch.currentSelection() {
            self.willPerformReplacement()
            self.viewportController?.replace(range, with: replaceTextField.text ?? "")
            self.didPerformReplacement()
            return
        }
        
        if let search = self.currentSearch, 
            search.selectedIndex == nil {
            _ = self.advanceSearhIndex(forward: true)
        }
    }
    
    @objc func performReplaceAll() {
        // Perform replacement in reverse we don't have to deal with range changes
        guard let results = currentSearch?.results,
            let query = self.currentSearch?.query, !query.isEmpty else {
            return
        }
        
        self.willPerformReplacement()
        self.viewportController?.replaceAll(results.reversed(), with: replaceTextField.text ?? "")
        self.didPerformReplacement()
    }
    
    func willPerformReplacement() {
        self.removeAllAttributes()
    }
    
    func didPerformReplacement() {
        guard let selectedIndex = currentSearch?.selectedIndex,
            let oldResultCount = self.currentSearch?.results.count else {
            return
        }
        
        self.performSearch()
        guard let newResults = self.currentSearch?.results, !newResults.isEmpty else {
            return
        }
        
        var newIndex: Int
        if oldResultCount == newResults.count {
            newIndex = selectedIndex + 1
        } else {
            newIndex = selectedIndex
        }
        if newIndex >= newResults.count {
            newIndex = 0
        }
        self.setSearchIndex(index: newIndex)
    }
    
    func setSearchIndex(index: Int) {
        self.selectionIndexWillChange()
        self.currentSearch?.selectedIndex = index
        self.selectionIndexDidChange()
        
    }
    
    func selectionIndexWillChange() {
        guard let _ = self.currentSearch else {
            return
        }
        self.removeAttributeForCurrentSelection()
        self.addNormalAttributeForCurrentSelection()
    }
    
    func selectionIndexDidChange() {
        guard let search = self.currentSearch else {
            return
        }
        
        self.resultCountLabel.text = "\((search.selectedIndex ?? 0) + 1) of \(search.results.count)"
        self.addHighlightAttributeForCurrentSelection()
        if let rect = rectForCurrentSelection() {
            self.viewportController?.scroll(to: rect.origin)
        }
        self.layoutManager.textViewportLayoutController.layoutViewport()
        replaceButton.isEnabled = search.selectedIndex != nil
    }
    
    func advanceSearhIndex(forward: Bool) -> Bool {
        guard let search = self.currentSearch else {
            return true
        }
        
        self.selectionIndexWillChange()
        
        let didAdvance: Bool
        if forward {
            didAdvance = search.moveToNextIndexIfPossible()
        } else {
            didAdvance = search.moveBackIfPossible()
        }
        
        self.selectionIndexDidChange()
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
        self.allActiveAttributes.append(RangedAttribute(attribute: attribute, range: range, value: value))
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
        containerView.frame = CGRect(x: self.view.frame.width - width - 2, y: 5, width: width - 2, height: height)
    }
}
