//
//  TextEditor.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/27/24.
//

import SwiftUI
import UIKit

typealias TextAttributes = [NSAttributedString.Key: Any]

struct Cursor {
    
}


class LineNumber {
    let number: Int
    let y:CGFloat
    
    init(number: Int, y: CGFloat) {
        self.number = number
        self.y = y
    }
}

class GutterView: UIView {
    var lineNumbers: [LineNumber] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        
        for number in self.lineNumbers {
            let line = "\(number.number)"
            let size = line.size(withAttributes: attributes)
            let drawRect = CGRect(x: rect.origin.x, y: rect.origin.y + number.y - size.height/2, width: rect.width - 2, height: size.height)
            line.draw(in: drawRect, withAttributes: attributes)
        }
        super.draw(rect)
    }
}

class VCTextEditorViewController: UIViewController, UITextViewDelegate {
    let textView = UITextView()
    var gutterView: GutterView = GutterView()
    let gutterWidth: CGFloat = 25
    
    override func viewDidLoad() {
        self.view.addSubview(textView)
        textView.isScrollEnabled = true
        textView.showsHorizontalScrollIndicator = true
        textView.showsVerticalScrollIndicator = true
        textView.isUserInteractionEnabled = true
        textView.hoverStyle = .none
        textView.textContainerInset = UIEdgeInsets(top: 0, left: gutterWidth, bottom: 0, right: 0)
        
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.textView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.textView.delegate = self
        
        self.gutterView.backgroundColor = .white.withAlphaComponent(0.65)
        self.textView.addSubview(gutterView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        print("Text change")
        self.updateGutterView()
    }
    
    override func viewDidLayoutSubviews() {
        print("Layout")
        self.updateGutterView()
    }
    
    func updateGutterView() {
        var lineNumbers = [LineNumber]()
        var lastOffset = 0
        let newLines = textView.text.indicesOf(string: "\n")
        for (number, offset) in newLines.enumerated() {
            let p0 = textView.position(from: textView.beginningOfDocument, offset: lastOffset)!
            let p1 = textView.position(from: textView.beginningOfDocument, offset: offset)!
            let rect = textView.firstRect(for: textView.textRange(from: p0, to: p1)!)
            lineNumbers.append(LineNumber(number: number + 1, y: rect.maxY - rect.height/2))
            
            lastOffset = offset + 1
        }
        
        let p0 = textView.position(from: textView.beginningOfDocument, offset: lastOffset)!
        let p1 = textView.position(from: textView.endOfDocument, offset: 0)!
        let rect = textView.firstRect(for: textView.textRange(from: p0, to: p1)!)
        lineNumbers.append(LineNumber(number: newLines.count + 1, y: rect.maxY - rect.height/2))
        
        gutterView.lineNumbers = lineNumbers
        gutterView.frame = CGRect(x: 0, y: 0, width: gutterWidth, height: self.textView.contentSize.height)
        gutterView.setNeedsDisplay()
    }

    
    
    func update(_ text: String) {
        textView.text = text
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
