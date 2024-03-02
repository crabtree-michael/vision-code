//
//  TextEditor.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/27/24.
//

import SwiftUI
import UIKit
import CodeEditLanguages

typealias TextAttributes = [NSAttributedString.Key: Any]

class VCTextEditorViewController: UIViewController, 
                                    UITextViewDelegate,
                                    UIScrollViewDelegate,
                                    NSTextLayoutManagerDelegate, NSTextStorageDelegate, FindViewportController {
    var textView: VCTextInputView!
    let layoutManager = NSTextLayoutManager()
    var gutterView: GutterView = GutterView()
    let gutterWidth: CGFloat = 25
    
    var contentObserver: NSKeyValueObservation?
    
    var hasUpdateAllYs: Bool = true
    
    let contentStorage = NSTextContentStorage()
    let textUndoManager: TextUndoManager
    
    let attributes: TextAttributes
    
    var onTextChanges: ((String) -> ())?
    
    var onFindInFileSet: ((FindInFileState) -> ())?
    
    let editMenu = EditMenu()
    
    let editMenuSize = CGSize(width: 93, height: 25)
    
    var treeSitterManager: TreeSitterManager?
    var highlighter: Highlighter?
    
    var findController: FindViewController!
    
    var overlayView = UIView()
    
    let theme: Theme
    var backgroundColor: UIColor {
        return theme.backgroundColor
    }
    
    init() {
        self.theme = try! Theme(name: "OneDark-Pro")
        self.attributes = [
            .foregroundColor: self.theme.primaryColor() ?? .white,
            .font: UIFont(name: "Menlo", size: 14)!,
        ]
        self.textUndoManager = TextUndoManager(storage: self.contentStorage)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.view.backgroundColor = self.backgroundColor
        
        let container = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        textView = VCTextInputView(
            manager: layoutManager,
            content: contentStorage,
            theme: theme)
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
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 64, right: 0)
        
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
        
        self.gutterView.backgroundColor = self.backgroundColor.withAlphaComponent(0.9)
        self.textView.addSubview(gutterView)
        
        self.textView.addSubview(overlayView)
        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.overlayView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.overlayView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.overlayView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.overlayView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.overlayView.addSubview(editMenu)
        self.editMenu.isHidden = true
        self.editMenu.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.editMenu.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: -25),
            self.editMenu.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            self.editMenu.widthAnchor.constraint(equalToConstant: editMenuSize.width),
            self.editMenu.heightAnchor.constraint(equalToConstant: editMenuSize.height)
        
        ])
        
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
            self.findController.isActive = false
            self.onFindInFileSet?(.hidden)
        }
        
        self.textView.onDidDeslectText = {
            self.editMenu.isHidden = true
        }
        
        self.textView.onOpenFindInFile = {
            self.findController.isActive = true
            self.findController.textField.becomeFirstResponder()
            self.onFindInFileSet?(.find)
        }
        
        self.textView.onUndoPressed = self.textUndoManager.undo
        self.textView.onRedoPressed = self.textUndoManager.redo
        
        findController = FindViewController(layoutManager: layoutManager, storage: contentStorage)
        self.overlayView.addSubview(findController.view)
        self.addChild(findController)
        findController.didMove(toParent: self)
        findController.viewportController = self
        
        findController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.findController.view.leadingAnchor.constraint(equalTo: self.overlayView.leadingAnchor),
            self.findController.view.trailingAnchor.constraint(equalTo: self.overlayView.trailingAnchor),
            self.findController.view.topAnchor.constraint(equalTo: self.overlayView.topAnchor),
            self.findController.view.bottomAnchor.constraint(equalTo: self.overlayView.bottomAnchor)
        ])
        
        findController.isActive = false
        findController.didSetState = { value in
            self.onFindInFileSet?(value)
        }
        
        gutterView.lineHeight = textView.lineHeight
        
        textView.languageTokenizer = Tokenizer(provider: self.contentStorage)
        self.textView.add(observer: self.textUndoManager)
    }
    
    deinit {
        contentObserver?.invalidate()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let viewRange = layoutManager.textViewportLayoutController.viewportRange,
           !(highlighter?.highlightedRange?.has(subrange: viewRange, in: self.contentStorage) ?? true) {
            let start = self.contentStorage.location(viewRange.location, offsetBy: -1000) ?? self.contentStorage.documentRange.location
            let end = self.contentStorage.location(viewRange.endLocation, offsetBy: 1000) ?? self.contentStorage.documentRange.endLocation
            
            if let range = NSTextRange(location: start, end: end){
                highlighter?.highlight(in: range)
            }
        }
        
        layoutManager.textViewportLayoutController.layoutViewport()
        
        gutterView.frame = CGRect(x: textView.contentOffset.x, 
                                  y: gutterView.bounds.minY,
                                  width: gutterView.frame.width,
                                  height: gutterView.frame.height)
    }
    
    override func viewDidLayoutSubviews() {
        highlighter?.highlightViewport()
        layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func update(_ text: String, language: CodeLanguage, findInFileState: FindInFileState, tabWidth: TabWidth) {
        switch(findInFileState) {
        case .find:
            self.findController.isActive = true
        case .findAndReplace:
            self.findController.isActive = true
            if !self.findController.isShowingReplace {
                self.findController.toggleReplace()
            }
        case .hidden:
            self.findController.isActive = false
        }
        
        textView.tabWidth = tabWidth
        
        if language != .default && language != self.treeSitterManager?.language {
            do {
                let treeSitter = try TreeSitterManager(language: language,
                                                       provider: self.contentStorage)
                let highlighter = try Highlighter(theme: self.theme,
                                                treeSitterManager: treeSitter,
                                                  layoutManager: self.layoutManager,
                                                  provider: self.contentStorage)
                
                
                treeSitter.set(text: text)
                if let m = self.treeSitterManager {
                    textView.remove(observer: m)
                }
                textView.add(observer: treeSitter)
                self.highlighter = highlighter
                self.treeSitterManager = treeSitter
            } catch {
                print("Failed to initalize highlighter \(error)")
            }
        }
        
        guard (text != contentStorage.textStorage?.string) else {
            return
        }
        
        textView.prepareForReplacement()
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        contentStorage.performEditingTransaction {
            contentStorage.textStorage!.setAttributedString(attributedString)
        }
        textView.findWidestTextFragement()
        highlighter?.highlightViewport(async: false)
        layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if findController.isActive {
            findController.textDidChange()
        }
        
        self.onTextChanges?(textStorage.string)
    }
    
    func searchContent() -> String {
        return self.contentStorage.textStorage?.string ?? ""
    }
    
    func scroll(to point: CGPoint) {
        self.textView.scrollRectToVisible(CGRect(x: point.x, y: point.y, width: 100, height: 100), animated: true)
    }
    
    func replace(_ range: NSTextRange, with value: String) {
        self.textView.replace(range: range, with: value)
    }
    
    func replaceAll(_ ranges: [NSTextRange], with value: String) {
        let replacements = ranges.map { Replacement(text: value, range: $0) }
        self.textView.perform(replacements: replacements)
    }
    
}

struct VCTextEditor: UIViewControllerRepresentable {
    typealias UIViewControllerType = VCTextEditorViewController
    
    @Binding var text: String
    @Binding var language: CodeLanguage
    @Binding var findInFileState: FindInFileState
    @Binding var tabWidth: TabWidth
    
    func makeUIViewController(context: Context) -> VCTextEditorViewController {
        let controller = VCTextEditorViewController()
        controller.view.addSubview(controller.textView)

        return controller
    }

    func updateUIViewController(_ uiViewController: VCTextEditorViewController, context: Context) {
        uiViewController.onTextChanges = { text in
            DispatchQueue.main.async {
                self.text = text
            }
        }
        uiViewController.onFindInFileSet = { value in
            if value != self.findInFileState {
                self.findInFileState = value
            }
        }
        uiViewController.update(text, 
                                language: language, 
                                findInFileState: findInFileState,
                                tabWidth: tabWidth)
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

extension NSTextRange {
    func has(subrange: NSTextRange, in provider: NSTextElementProvider) -> Bool? {
        guard let start = self.offset(provider: provider), let end = self.endOffset(provider: provider),
              let subStart = subrange.offset(provider: provider),
                let subEnd = subrange.endOffset(provider: provider) else {
            return nil
        }
        
        return start <= subStart && end >= subEnd
    }
}
