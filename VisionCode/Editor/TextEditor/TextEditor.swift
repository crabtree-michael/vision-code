//
//  TextEditor.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/27/24.
//

import SwiftUI
import UIKit

typealias TextAttributes = [NSAttributedString.Key: Any]

class VCTextEditorViewController: UIViewController, 
                                    UITextViewDelegate,
                                    UIScrollViewDelegate,
                                    NSTextLayoutManagerDelegate, NSTextStorageDelegate {
    var textView: VCTextInputView!
    let layoutManager = NSTextLayoutManager()
    var gutterView: GutterView = GutterView()
    let gutterWidth: CGFloat = 25
    
    var contentObserver: NSKeyValueObservation?
    
    var hasUpdateAllYs: Bool = true
    
    let contentStorage = NSTextContentStorage()
    
    let attributes: TextAttributes = [
        .font: UIFont(name: "Menlo", size: 12)!,
        .foregroundColor: UIColor.white
    ]
    
    var onTextChanges: ((String) -> ())?
    
    let editMenu = EditMenu()
    
    let editMenuSize = CGSize(width: 93, height: 25)

    override func viewDidLoad() {
        let container = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        textView = VCTextInputView(
            manager: layoutManager,
            content: contentStorage)
        textView.contentSize = CGSize(width: 100, height: 10000)
    
        layoutManager.textContainer = container
        layoutManager.delegate = self
        layoutManager.textViewportLayoutController.delegate = textView
        layoutManager.replace(contentStorage)
        
        contentStorage.textStorage = NSTextStorage()
        contentStorage.textStorage?.delegate = self
        contentStorage.addTextLayoutManager(layoutManager)
        contentStorage.primaryTextLayoutManager = layoutManager
        contentStorage.automaticallySynchronizesToBackingStore = true
        contentStorage.automaticallySynchronizesTextLayoutManagers = true
        
        self.view.addSubview(textView)
        textView.isScrollEnabled = true
        textView.showsHorizontalScrollIndicator = true
        textView.showsVerticalScrollIndicator = true
        textView.alwaysBounceHorizontal = false
        textView.alwaysBounceVertical = true
        textView.attributes = self.attributes
        textView.insets = UIEdgeInsets(top: 0, left: gutterWidth, bottom: 0, right: 10)
        
        textView.delegate = self
        
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.textView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.gutterView.frame = CGRect(x: 0, y: 0, width: gutterWidth, height: 1000)
        
        contentObserver = self.textView.observe(\.contentSize, changeHandler: { [weak self] view, value in
            self?.gutterView.frame = CGRect(x: self?.textView.contentOffset.x ?? 0,
                                            y: self?.gutterView.bounds.minY ?? 0,
                                            width: self?.gutterWidth ?? 0,
                                            height: view.contentSize.height)
            self?.gutterView.setNeedsDisplay()
        })
        
        self.gutterView.backgroundColor = .darkGray.withAlphaComponent(0.95)
        self.textView.addSubview(gutterView)
        
        self.textView.addSubview(editMenu)
        self.editMenu.frame = CGRect(x: 100, y: 100, width: editMenuSize.width, height: editMenuSize.height)
        self.textView.bringSubviewToFront(self.editMenu)
       self.editMenu.isHidden = true
        
        self.editMenu.copyButton.addAction(UIAction(title: "Copy") { _ in
            self.textView.copySelection()
        }, for: .touchDown)
        
        self.editMenu.pasteButton.addAction(UIAction(title: "Paste") { _ in
            self.textView.pasteText()
        }, for: .touchDown)
        
        self.editMenu.cutButton.addAction(UIAction(title: "Cut") { _ in
            self.textView.cutSelection()
        }, for: .touchDown)
        
        
        self.textView.onDidSelectText = {
            self.editMenu.isHidden = false
        }
        
        self.textView.onDidDeslectText = {
            self.editMenu.isHidden = true
        }
    }
    
    deinit {
        contentObserver?.invalidate()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        layoutManager.textViewportLayoutController.layoutViewport()
        
        gutterView.frame = CGRect(x: textView.contentOffset.x, y: gutterView.bounds.minY, width: gutterView.frame.width, height: gutterView.frame.height)
        forceEditMenuToBottom()
    }
    
    override func viewDidLayoutSubviews() {
        layoutManager.textViewportLayoutController.layoutViewport()
        forceEditMenuToBottom()
    }
    
    func forceEditMenuToBottom() {
        let y = textView.contentOffset.y + textView.frame.height - 50
        let x = textView.contentOffset.x + textView.frame.width/2 - 50
        self.editMenu.frame = CGRect(x: x, y: y, width: editMenuSize.width, height: editMenuSize.height)
    }
    
    func update(_ text: String) {
        guard text != contentStorage.textStorage?.string else {
            return
        }
        
        textView.prepareForReplacement()
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        contentStorage.performEditingTransaction {
            contentStorage.textStorage!.setAttributedString(attributedString)
        }

        textView.findWidestTextFragement()
        layoutManager.textViewportLayoutController.layoutViewport()
        
        gutterView.lineHeight = textView.lineHeight
        gutterView.setNeedsDisplay()
    }
    
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        self.onTextChanges?(textStorage.string)
    }
    
}

struct VCTextEditor: UIViewControllerRepresentable {
    typealias UIViewControllerType = VCTextEditorViewController
    
    @Binding var text: String
    
    func makeUIViewController(context: Context) -> VCTextEditorViewController {
        let controller = VCTextEditorViewController()
        controller.view.addSubview(controller.textView)

        return controller
    }

    func updateUIViewController(_ uiViewController: VCTextEditorViewController, context: Context) {
        uiViewController.onTextChanges = { text in
            self.text = text
        }
        uiViewController.update(text)
    }
}

extension String {
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
}
