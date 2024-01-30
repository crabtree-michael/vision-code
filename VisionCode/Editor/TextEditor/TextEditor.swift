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
        contentStorage.addTextLayoutManager(layoutManager)
        contentStorage.primaryTextLayoutManager = layoutManager
        contentStorage.automaticallySynchronizesToBackingStore = true
        contentStorage.automaticallySynchronizesTextLayoutManagers = true
        self.view.addSubview(textView)
        textView.becomeFirstResponder()
        
        textView.isScrollEnabled = true
        textView.showsHorizontalScrollIndicator = true
        textView.showsVerticalScrollIndicator = true
        textView.alwaysBounceHorizontal = false
        textView.alwaysBounceVertical = true
        textView.attributes = self.attributes
        textView.insets = UIEdgeInsets(top: 0, left: gutterWidth, bottom: 0, right: 0)
        
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
    }
    
    deinit {
        contentObserver?.invalidate()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        layoutManager.textViewportLayoutController.layoutViewport()
        
        gutterView.frame = CGRect(x: textView.contentOffset.x, y: gutterView.bounds.minY, width: gutterView.frame.width, height: gutterView.frame.height)
    }
    
    override func viewDidLayoutSubviews() {
        layoutManager.textViewportLayoutController.layoutViewport()
    }
    
    func update(_ text: String) {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        contentStorage.performEditingTransaction {
            contentStorage.textStorage!.setAttributedString(attributedString)
        }

        textView.findWidestTextFragement()
        layoutManager.textViewportLayoutController.layoutViewport()
        
        gutterView.lineHeight = textView.lineHeight
        gutterView.setNeedsDisplay()
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
